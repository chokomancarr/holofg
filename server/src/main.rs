/*
 * Matchmaker for game lobbies
 * 
 * endpoints:
 *  - POST  /hello { "username"="..." } => { "id"=... }
 *  - GET   /poll { "id"=... } (blocking w/ timeout) //take id so we can run poll in a separate socket
 *  - POST  /post { "id"=... }
 * 
 * lobby host:
 *  - /post { type="lobby_new" }  =>  { lobby_code="XXXX" }
 *  - /poll => { type="join_request", req_id=..., net_info="encoded sdp + ice" }
 *  - /post { type="join_accept", req_id=..., net_info="encoded sdp + ice" }
 *  - /post { type="lobby_close" }
 * 
 * lobby client:
 *  - /post { type="lobby_has", lobby_code=XXXX } => 200 OR 404
 *  - /post { type="lobby_join", lobby_code="XXXX", net_info="encoded sdp + ice" }  =>  { type="fail", reason="...." } OR { type="ok" }
 *  - /poll => { type="host_info", host_id=..., net_info="encoded sdp + ice" }
 *  - /post { type="lobby_leave" }
 */

use std::collections::HashMap;
use std::io::BufRead;
use std::io::BufReader;
use std::io::Read;
use std::net::TcpListener;
use std::net::TcpStream;
use std::process::Stdio;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::RwLock;
use std::sync::mpsc;
use std::time::Duration;
use std::time::SystemTime;
use std::convert::TryFrom;
use rand::Rng;
use threadpool::ThreadPool;

type ID = usize;
type TIME = u64;
type _State = Arc<RwLock<State>>;
enum MSG {
    S(String),
    SKIP
}
type DICT = serde_json::Map<String, serde_json::Value>;
type RET = String;

const MAX_CLIENTS : usize = 20;
const MAX_THREADS : usize = 6;

// ----------------------- TYPES

struct State {
    free_ids : RwLock<Vec<usize>>, //only used by hello
    clients: [RwLock<Option<Client>>; MAX_CLIENTS], //this will be hogged in /poll, so we structure like this
    lobbies: RwLock<HashMap<String, RwLock<Lobby>>> //nobody will hog this
}
struct Client {
    username: String,
    last_polled: TIME,
    msgs: (RwLock<mpsc::Sender<MSG>>, Mutex<mpsc::Receiver<MSG>>)
}
struct Lobby {
    host: ID,
    client: Option<ID>
}

// ----------------------- UTIL

fn current_time() -> TIME {
    SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_secs()
}

fn http_ret<S : Into<String>>(code : u16, body : S) {
    format!("HTTP/1.1 {} UWU\nContent-Type: application/json\nContent-Length: {}\n\n{}",
        code, body.into().len(), &body
    )
}
fn http_ok<S : Into<String>>(body : S) { http_ret(200, body) }

fn _mpsc_send<S : Into<String>>(host : &Client, msg : S) {
    host.msgs.0.read().unwrap().send(MSG::S(msg.into()))
}
fn _mpsc_send_skip(host : &Client) {
    host.msgs.0.read().unwrap().send(MSG::SKIP)
}

fn get_bool<T>(obj : &DICT, key : &str) -> Result<bool, RET> {
    match obj.get(key) {
        None => Err(http_ret(400, "key not in body")),
        Some(v) => match v.as_bool() {
            None => Err(http_ret(400, "key value not bool")),
            Some(b) => Ok(b)
        }
    }
}
fn get_str<T>(obj : &DICT, key : &str) -> Result<String, RET> {
    match obj.get(key) {
        None => Err(http_ret(400, "key not in body")),
        Some(v) => match v.as_str() {
            None => Err(http_ret(400, "key value not string")),
            Some(s) => Ok(s.to_owned())
        }
    }
}
fn get_num<T>(obj : &DICT, key : &str) -> Result<i64, RET> {
    match obj.get(key) {
        None => Err(http_ret(400, "key not in body")),
        Some(v) => match v.as_number() {
            None => Err(http_ret(400, "key value not string")),
            Some(s) => match s.as_i64() {
                None => Err(http_ret(400, "key value not i64")),
                Some(u) => Ok(u)
            }
        }
    }
}

fn get_client<'c, 'b:'c, 'a:'b>(ci: ID, state : &'a State) -> (RwLockReadGuard<'b, Client>, &'c Client) {
    let lock = state.clients[ci].read().unwrap()
    let client = lock.as_ref().expect("host entry missing");
    (lock, client)
}

// ----------------------- MAIN

fn main() {
    let state = State {
        free_ids: RwLock::new((0..MAX_CLIENTS).collect()),
        clients: std::array::from_fn(|_| RwLock::new(None)),
        lobbies: RwLock::new(HashMap::new())
    };
    let state = Arc::new(RwLock::new(state));

    let thread_pool = ThreadPool::new(MAX_THREADS);

    let listener = TcpListener::bind("localhost:0").unwrap();
    let local_addr = listener.local_addr().unwrap();

    let _ngrok = std::process::Command::new("ngrok")
        .args([ "http", "--domain=equipped-chamois-big.ngrok-free.app", &local_addr.port().to_string() ])
        .stdout(Stdio::null())
        .spawn().expect("could not spawn ngrok");

    println!("listening on {:?}", &local_addr);

    for stream in listener.incoming() {
        let stream = stream.unwrap();
        let state = state.clone();

        thread_pool.execute(move || {
            handle_connection(stream, state);
        });
    }
}

fn handle_connection(mut stream : TcpStream, state : _State) {
    let (path, method, client_id, body) = {
        let buf_reader = BufReader::new(&mut stream);
        let mut lines = buf_reader.lines().map(|l| l.unwrap());
        
        let mut request = lines.next().split(" ");
        let path = request.next().unwrap();
        let path = &path[1..];
        let method = request.next().unwrap();
        
        let mut body_length = 0;
        let mut client_id = 0;
        for header in lines.by_ref().take_until(|l| !l.size()) {
            if header.starts_with("Content-Length:") {
                let n = header.rsplit_once(":").unwrap().1;
                body_length = n.parse::<usize>().unwrap();
            }
            elif header.starts_with("client_id:") {
                let n = header.rsplit_once(":").unwrap().1;
                client_id = n.parse::<ID>().unwrap();
            }
        }
        (path, method, client_id, body)
    }
    
    let body = if body_length > 0 {
        //we assume the request json is in 1 line. this makes life easier
        let body = lines.next()
        let body = serde_json::from_str::<serde_json::Value>(&body);
        if let Ok(body) = body {
            if let serde_json::Value::Object(v) = body {
                Some(v)
            }
            else { None }
        }
        else { None }
    }
    else { Some(DICT::new()) }
    
    let ret = if let Some(body) = body {
        println!("REQ {} => {} {}", client_id, method, path);
        if method == "GET" {
            match path {
                "poll" => req_poll(client_id, state),
                _ => http_ret(400, "unsupported GET url")
            }
        } elif method == "POST" {
            match path {
                "hello" => req_hello(state, body),
                "stop_poll" => req_stop_poll(client_id, state),
                "lobby_new" => req_lobby_new(client_id, state),
                "lobby_list" => req_lobby_list(client_id, state, body),
                "lobby_has" => req_lobby_has(client_id, state, body),
                "lobby_join" => req_lobby_join(client_id, state, body),
                "join_accept" => req_join_accept(client_id, state, body),
                "client_joined" => req_client_joined(client_id, state, body),
                _ => http_ret(400, "unsupported POST url")
            }
        } else {
            http_ret(400, "unsupported HTTP method")
        }
    } else {
        http_ret(400, "malformed body")
    }
    
    let buf = ret.to_bytes();
    stream.write_all(&buf).expect("could not write response");
    stream.flush().expect("flushing tcpstream failed");
}

// curl -X POST -H "type:hello" -d "{ "\""username"\"":"\""foo"\"" }" localhost:8080/hello
fn req_hello(state: _State, body: DICT) -> RET {
    let username = match get_str(&body, "username") { Ok(s) => s, Err(e) => return e };
    
    println!("locking state");
    let state = state.read().unwrap();

    let next_id = {
        println!("locking free_ids");
        let mut used = state.free_ids.write().unwrap();
        used.pop()
    };
    if next_id.is_none() {
        return ret_err(500, "out of client slots");
    }
    let next_id = next_id.unwrap();

    let mpsc = mpsc::channel();

    println!("locking client");
    let mut client = state.clients[next_id].write().unwrap();

    println!("adding user {}", &username);
    *client = Some(Client {
        username,
        last_polled: current_time(),
        msgs: (RwLock::new(mpsc.0), Mutex::new(mpsc.1))
    });
    
    http_ok(format!("{{\"id\":{}}}", next_id))
}

fn req_poll(ci: ID, state: _State) -> RET {
    let state = state.read().unwrap();
    let (_, client) = get_client(ci, state);
    //let client = state.clients[ci].read().unwrap();
    //let client = client.as_ref().expect("client not registered");
    let msg = client.msgs.1.lock().unwrap().recv_timeout(Duration::from_secs(30));
    match msg {
        Ok(s) => match s {
            MSG::S(s) => http_ok(s),
            MSG::SKIP => http_ret(204, "no message")
        },
        Err(_) => http_ret(204, "no message")
    }
}

async fn req_stop_poll(ci: ID, state: _State) -> RET {
    let state = state.read().unwrap();
    let host = state.clients[ci].read().unwrap();
    let host = host.as_ref().expect("client not registered");

    let msg = "{\"type\":\"kill_poll\"}";
    _mpsc_send(host, msg);
    
    http_ok("{}")
}

fn req_lobby_new(ci: ID, state: _State) -> RET {
    let mut state = state.read().unwrap();
    
    let lobbies = state.lobbies.write().unwrap();

    let mut rng = rand::thread_rng();
    let lobby_code = loop {
        let code = (0..4).map(|_| rng.gen_range(b'A'..=b'Z') as char).into_iter().collect();
        if !lobbies.contains_key(&lobby_code) {
            break code;
        }
    }

    let ret = http_ok(format!("{{\"lobby_code\":\"{}\"}}", lobby_code));

    lobbies.insert(lobby_code.clone(), Lobby { host: cid, client: None });

    ret
}

fn req_lobby_list(ci: ID, state: _State, body : DICT) -> RET {
    let state = state.read().unwrap();
    let show_all = match get_bool(body, "all") { Ok(s) => s, Err(e) => return e };

    let lobbies = state.lobbies.read().unwrap();

    let lbs = lobbies.iter().filter(|(_nm, lb)| show_all || lb.client.is_none());
    let res = lbs.map(|(k, v)| {
        let host = state.clients[res.host].read().unwrap()
        let host = host.as_ref().expect("host entry missing");
        format!("{{\"lobby_code\":\"{}\",\"host_name\":\"{}\"}}", k, host.username)
    });

    http_ok(format!("{{\"lobbies\":[{}]}}", res.collect::<Vec<String>>().join(", ")))
}

fn req_lobby_has(ci: ID, state: _State, body : DICT) -> RET {
    let state = state.read().unwrap();
    let lobby_code = match get_str(&body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    
    let lobbies = state.lobbies.read().unwrap();

    let lobby = match lobbies.get(&lobby_code) { Some(l) => l, None => 
        return http_ret(404, "lobby does not exist");
    };
    let host = state.clients[lobby.host].read().unwrap()
    let host = host.as_ref().expect("host entry missing");
    if lobby.client.is_some() {
        return http_ret(403, "lobby is full");
    }
    
    http_ok(format!("{{\"host_id\":{}, \"host_name\":{}}}", lobby.host, host.username))
}

fn req_lobby_join(state : &_State, cid : ID, body : DICT) -> RET {
    let state = state.read().unwrap();
    let lobby_code = match get_str(&body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    let net_info = match get_str(&body, "net_info") { Ok(s) => s, Err(e) => return e };
    
    let lobbies = state.lobbies.read().unwrap();
    
    let lobby = match lobbies.get(&lobby_code) { Some(l) => l, None => 
        return http_err(404, "lobby does not exist")
    };
    if lobby.client.is_some() {
        return http_err(403, "lobby is full")
    }
    
    let host = state.clients[lobby.host].read().unwrap();
    let host = host.as_ref().expect("host entry missing");
    let client = state.clients[ci].read().unwrap();
    let client = client.as_ref().expect("client entry missing");
    
    let msg = format!("{{ \"type\":\"join_request\", \"lobby_code\":\"{}\", \"req_id\":{}, \"req_name\":\"{}\" \"net_info\":{} }}", lobby_code, cid, &client.username, net_info);
    _mpsc_send(host, msg);
    
    http_ok("{}")
}

async fn req_join_accept(ci: ID, state: _State, body : DICT) -> RET {
    let state = state.read().unwrap();
    let req_cid = match get_num(&body, "req_id") { Ok(s) => s, Err(e) => return e };
    let net_info = match get_str(&body, "net_info") { Ok(s) => s, Err(e) => return e };
    
    let requestor = state.clients[req_cid].read().unwrap();
    let requestor = requestor.read().expect("requestor id invalid");
    
    let msg = format!("{{ \"type\":\"host_info\", \"net_info\":{} }}", net_info);
    _mpsc_send(requestor, msg);
    
    http_ok("{}")
}

async fn req_client_joined(ci: ID, state: _State, body : DICT) -> RET {
    let state = state.read().unwrap();

    let lobby_code = match get_str(&body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    let client_id = match get_num(&body, "client_id") { Ok(s) => s, Err(e) => return e };
    
    let mut lobbies = state.lobbies.write().unwrap();
    let lobby = match lobbies.get_mut(&lobby_code) { Some(l) => l, None => 
        return http_ret(404, "lobby does not exist");
    };
    
    lobby.client = Some(client_id);
    
    http_ok("{}")
}
/*
async fn _lobby_leave(state : &_State, _cid : ID, body : DICT) -> tide::Result {
    
    unimplemented!()
}

async fn _lobby_close(state : &_State, _cid : ID, body : DICT) -> tide::Result {
    
    unimplemented!()
}*/