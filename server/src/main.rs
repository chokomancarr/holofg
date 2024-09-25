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
use std::io::Write;
use std::net::TcpListener;
use std::net::TcpStream;
use std::process::Stdio;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::mpsc;
use std::sync::mpsc::SendError;
use std::time::Duration;
use std::time::SystemTime;
use rand::Rng;
use threadpool::ThreadPool;
use parking_lot::{RwLock, RwLockReadGuard, MappedRwLockReadGuard};

const MAX_CLIENTS: usize = 20;
const MAX_THREADS: usize = 6;
const GC_KILL_T: u64 = 60;
const GC_RATE: Duration = Duration::from_secs(GC_KILL_T);

type ID = usize;
type TIME = u64;
type _State = Arc<State>;
enum MSG {
    S(String),
    #[allow(dead_code)]
    SKIP
}
type DICT = serde_json::Map<String, serde_json::Value>;
type RET = String;

// ----------------------- TYPES

struct State {
    free_ids: RwLock<Vec<usize>>, //only used by hello
    clients: [RwLock<Option<Client>>; MAX_CLIENTS], //this will be hogged in /poll, so we structure like this
    lobbies: RwLock<HashMap<String, Lobby>> //nobody will hog this
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

fn http_ret<S: Into<String>>(code: u16, body: S) -> RET {
    let s = body.into();
    format!("HTTP/1.1 {} UWU\nContent-Type: application/json\nContent-Length: {}\n\n{}",
        code, s.len(), &s
    )
}
fn http_ok<S: Into<String>>(body: S) -> RET { http_ret(200, body) }

fn _mpsc_send<S: Into<String>>(host: &Client, msg: S) -> Result<(), SendError<MSG>> {
    host.msgs.0.read().send(MSG::S(msg.into()))
}
fn _mpsc_send_skip(host: &Client) -> Result<(), SendError<MSG>> {
    host.msgs.0.read().send(MSG::SKIP)
}

macro_rules! unwrap_or_ret {
    ( $e:expr ) => {
        match $e {
            Ok(x) => x,
            Err(r) => return r,
        }
    }
}
fn get_str(obj: &DICT, key: &str) -> Result<String, RET> {
    match obj.get(key) {
        None => Err(http_ret(400, format!("key '{}' not in body", key))),
        Some(v) => match v.as_str() {
            None => Err(http_ret(400, format!("key '{}' value not string", key))),
            Some(s) => Ok(s.to_owned())
        }
    }
}
macro_rules! get_str {
    ($obj:expr, $key:expr) => {
        unwrap_or_ret!(get_str($obj, $key))
    };
}
fn get_num(obj: &DICT, key: &str) -> Result<i64, RET> {
    match obj.get(key) {
        None => Err(http_ret(400, format!("key '{}' not in body", key))),
        Some(v) => match v.as_number() {
            None => Err(http_ret(400, format!("key '{}' value not number", key))),
            Some(s) => match s.as_i64() {
                None => Err(http_ret(400, format!("key '{}' value not int", key))),
                Some(u) => Ok(u)
            }
        }
    }
}
macro_rules! get_num {
    ($obj:expr, $key:expr) => {
        unwrap_or_ret!(get_num($obj, $key))
    };
}

fn get_client<'b, 'a:'b>(ci: ID, state: &'a State) -> MappedRwLockReadGuard<'_, Client> {
    let lock = state.clients[ci].read();
    RwLockReadGuard::map(lock, |c| c.as_ref().unwrap())
}

// ----------------------- MAIN

fn main() {
    let state = State {
        free_ids: RwLock::new((0..MAX_CLIENTS).collect()),
        clients: std::array::from_fn(|_| RwLock::new(None)),
        lobbies: RwLock::new(HashMap::new())
    };
    let state = Arc::new(state);

    let thread_pool = ThreadPool::new(MAX_THREADS);

    let listener = TcpListener::bind("localhost:0").unwrap();
    let local_addr = listener.local_addr().unwrap();

    let _ngrok = std::process::Command::new("ngrok")
        .args([ "http", "--domain=equipped-chamois-big.ngrok-free.app", &local_addr.port().to_string() ])
        .stdout(Stdio::null())
        .spawn().expect("could not spawn ngrok");

    println!("listening on {:?}", &local_addr);

    let _gc = {
        let state = state.clone();
        std::thread::spawn(move || {
            garbage_collector(state);
        })
    };

    for stream in listener.incoming() {
        let stream = stream.unwrap();
        let state = state.clone();

        thread_pool.execute(move || {
            let _ = handle_connection(stream, state);
        });
    }
}

fn garbage_collector(state: _State) {
    loop {
        std::thread::sleep(GC_RATE);
        let now = current_time();
        for (ci, cl) in state.clients.iter().enumerate() {
            let t = {
                let cl = cl.read();
                cl.as_ref().map_or(None, |v| Some(v.last_polled))
            };
            if let Some(t) = t {
                if (now - t) > GC_KILL_T {
                    remove_client(state.clone(), ci);
                }
            }
        }
    }
}

fn remove_client(state: _State, ci : ID) {
    *state.clients[ci].write() = None;
    
    //remove active lobbies, but when will this happen?
    //if its a full lobby, someone would have already told us about the disconnection
    //...unless both drops at the same time or its an empty lobby
    //in which case we can drop the lobby without sending info to the client
    let finder = {
        let lobbies = state.lobbies.read();
        lobbies.iter().find_map(|(k, &ref v)|
            if v.host == ci { Some(k.clone()) } else { None }
        )
    };
    if let Some(key) = finder {
        state.lobbies.write().remove(&key);
    }
}

fn handle_connection(mut stream: TcpStream, state: _State) -> std::io::Result<()> {
    let mut buf_reader = BufReader::new(&mut stream);
 
    const LF : u8 = b'\n';

    let mut buf = vec![];

    macro_rules! next_line {
        ($reader:ident, $buf:ident) => {{
            $buf.clear();
            $reader.read_until(LF, &mut $buf).unwrap();
            let res = std::str::from_utf8(&$buf).unwrap().trim();
            res.to_owned()
        }}
    }

    let (path, method, client_id, body_length) = {
        let line = next_line!(buf_reader, buf);
        let mut request = line.split(" ");
        let method = request.next().unwrap();
        let path = request.next().unwrap();
        let path = &path[1..];
        let mut body_length = 0;
        let mut client_id = 0;
        loop {
            let header = next_line!(buf_reader, buf);
            if header.is_empty() { break }
            if header.starts_with("Content-Length:") {
                let n = header.rsplit_once(":").unwrap().1.trim();
                body_length = n.parse::<usize>().unwrap();
            }
            else if header.starts_with("Client_id:") {
                let n = header.rsplit_once(":").unwrap().1.trim();
                client_id = n.parse::<ID>().unwrap();
            }
        }
        (path.to_owned(), method.to_owned(), client_id, body_length)
    };
    
    let body = if body_length > 0 {
        buf.resize(body_length, 0);
        buf_reader.read_exact(&mut buf).expect("could not read body");
        let body = serde_json::from_slice::<serde_json::Value>(&buf);
        if let Ok(body) = body {
            if let serde_json::Value::Object(v) = body {
                Some(v)
            }
            else { None }
        }
        else { None }
    }
    else { Some(DICT::new()) };
    
    let ret = if let Some(body) = body {
        println!("REQ {} => {} {}", client_id, method, path);
        if method == "GET" {
            match path.as_str() {
                "poll" => req_poll(client_id, state),
                _ => http_ret(400, "unsupported GET url")
            }
        } else if method == "POST" {
            match path.as_str() {
                "hello" => req_hello(state, body),
                "stop_poll" => req_stop_poll(client_id, state),
                "lobby_new" => req_lobby_new(client_id, state),
                "lobby_list" => req_lobby_list(client_id, state, body),
                "lobby_has" => req_lobby_has(client_id, state, body),
                "lobby_join" => req_lobby_join(client_id, state, body),
                "join_accept" => req_join_accept(client_id, state, body),
                "client_joined" => req_client_joined(client_id, state, body),
                "client_left" => req_client_left(client_id, state, body),
                "host_left" => req_host_left(client_id, state, body),
                _ => http_ret(400, format!("unsupported POST url {}", path))
            }
        } else {
            http_ret(400, format!("unsupported HTTP method {}", method))
        }
    } else {
        http_ret(400, "malformed body")
    };
    
    //these can fail if the user disconnects midway
    let buf = ret.into_bytes();
    stream.write_all(&buf)?;
    stream.flush()?;
    Ok(())
}

// curl -X POST -H "type:hello" -d "{ "\""username"\"":"\""foo"\"" }" localhost:8080/hello
fn req_hello(state: _State, body: DICT) -> RET {
    let username = get_str!(&body, "username");

    let next_id = {
        println!("locking free_ids");
        let mut used = state.free_ids.write();
        used.pop()
    };
    let Some(next_id) = next_id else {
        return http_ret(500, "out of client slots");
    };

    let mpsc = mpsc::channel();

    println!("locking client");
    let mut client = state.clients[next_id].write();

    println!("adding user {}", &username);
    *client = Some(Client {
        username,
        last_polled: current_time(),
        msgs: (RwLock::new(mpsc.0), Mutex::new(mpsc.1))
    });
    
    http_ok(format!("{{\"id\":{}}}", next_id))
}

fn req_poll(ci: ID, state: _State) -> RET {
    {
        let mut host = state.clients[ci].write();
        let host = host.as_mut().expect("client not registered");
        host.last_polled = current_time();
    }
    let client = get_client(ci, &state);
    //let client = state.clients[ci].read();
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

fn req_stop_poll(ci: ID, state: _State) -> RET {
    let host = state.clients[ci].read();
    let host = host.as_ref().expect("client not registered");

    let msg = "{\"type\":\"kill_poll\"}";
    if _mpsc_send(host, msg).is_err() {
        return http_ret(500, "could not send msg to poll");
    }
    
    http_ok("{}")
}

fn req_lobby_new(ci: ID, state: _State) -> RET {
    let mut lobbies = state.lobbies.write();

    let mut rng = rand::thread_rng();
    let lobby_code = loop {
        let code = (0..4).map(|_| rng.gen_range(b'A'..=b'Z') as char).into_iter().collect::<String>();
        if !lobbies.contains_key(&code) {
            break code;
        }
    };

    let ret = http_ok(format!("{{\"lobby_code\":\"{}\"}}", lobby_code));

    lobbies.insert(lobby_code.clone(), Lobby { host: ci, client: None });

    ret
}

fn req_lobby_list(_ci: ID, state: _State, body: DICT) -> RET {
    let show_all = get_num!(&body, "all") != 0;

    let lobbies = state.lobbies.read();

    let lbs = lobbies.iter().filter(|(_nm, lb)| show_all || lb.client.is_none());
    let res = lbs.map(|(k, v)| {
        let host = state.clients[v.host].read();
        let host = host.as_ref().expect("host entry missing");
        format!("{{\"lobby_code\":\"{}\",\"host_name\":\"{}\"}}", k, host.username)
    });

    http_ok(format!("{{\"lobbies\":[{}]}}", res.collect::<Vec<String>>().join(", ")))
}

fn req_lobby_has(_ci: ID, state: _State, body: DICT) -> RET {
    let lobby_code = get_str!(&body, "lobby_code");
    
    let lobbies = state.lobbies.read();

    let lobby = match lobbies.get(&lobby_code) { Some(l) => l, None => 
        return http_ret(404, "lobby does not exist")
    };
    let host = state.clients[lobby.host].read();
    let host = host.as_ref().expect("host entry missing");
    if lobby.client.is_some() {
        return http_ret(403, "lobby is full");
    }
    
    http_ok(format!("{{\"host_id\":{}, \"host_name\":\"{}\"}}", lobby.host, host.username))
}

fn req_lobby_join(ci: ID, state: _State, body: DICT) -> RET {
    let lobby_code = get_str!(&body, "lobby_code");
    let net_info = get_str!(&body, "net_info");
    
    let lobbies = state.lobbies.read();
    
    let lobby = match lobbies.get(&lobby_code) { Some(l) => l, None => 
        return http_ret(404, "lobby does not exist")
    };
    if lobby.client.is_some() {
        return http_ret(403, "lobby is full")
    }
    
    let host = state.clients[lobby.host].read();
    let host = host.as_ref().expect("host entry missing");
    let client = state.clients[ci].read();
    let client = client.as_ref().expect("client entry missing");
    
    let msg = format!("{{ \"type\":\"join_request\", \"lobby_code\":\"{}\", \"req_id\":{}, \"req_name\":\"{}\", \"net_info\":\"{}\" }}", lobby_code, ci, &client.username, net_info);
    if _mpsc_send(host, msg).is_err() {
        return http_ret(500, "could not send msg to poll");
    }
    
    http_ok("{}")
}

fn req_join_accept(_ci: ID, state: _State, body: DICT) -> RET {
    let req_cid = get_num!(&body, "req_id");
    let net_info = get_str!(&body, "net_info");
    
    let requestor = state.clients[req_cid as usize].read();
    let requestor = requestor.as_ref().expect("requestor id invalid");
    
    let msg = format!("{{ \"type\":\"host_info\", \"net_info\":\"{}\" }}", net_info);
    if _mpsc_send(requestor, msg).is_err() {
        return http_ret(500, "could not send msg to poll");
    }
    
    http_ok("{}")
}

fn req_client_joined(_ci: ID, state: _State, body: DICT) -> RET {
    let lobby_code = get_str!(&body, "lobby_code");
    let client_id = get_num!(&body, "client_id");
    
    let mut lobbies = state.lobbies.write();
    let lobby = match lobbies.get_mut(&lobby_code) { Some(l) => l, None => 
        return http_ret(404, "lobby does not exist")
    };
    
    lobby.client = Some(client_id as ID);
    
    http_ok("{}")
}

fn req_client_left(_ci: ID, state: _State, body: DICT) -> RET {
    let lobby_code = get_str!(&body, "lobby_code");
    
    let mut lobbies = state.lobbies.write();
    let lobby = match lobbies.get_mut(&lobby_code) { Some(l) => l, None => 
        return http_ret(404, "lobby does not exist")
    };
    
    lobby.client = None;
    
    http_ok("{}")
}

fn req_host_left(ci: ID, state: _State, body: DICT) -> RET {
    let lobby_code = get_str!(&body, "lobby_code");
    
    let mut lobbies = state.lobbies.write();
    let lobby = match lobbies.get_mut(&lobby_code) { Some(l) => l, None => 
        return http_ret(404, "lobby does not exist")
    };
    
    lobby.host = ci;
    lobby.client = None;
    
    //let client = state.clients[ci].read();
    //let client = requestor.as_ref().expect("client entry missing");
    
    //let msg = "{{ \"type\":\"become_host\" }}";
    //_mpsc_send(requestor, msg);
    
    http_ok("{}")
}