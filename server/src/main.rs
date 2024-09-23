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
use std::process::Stdio;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::RwLock;
use std::sync::mpsc;
use std::time::Duration;
use std::time::SystemTime;
use std::convert::TryFrom;
use rand::Rng;
use tide::Request;
use ngrok::prelude::*;

type ID = u32;
type TIME = u64;
type _State = Arc<RwLock<State>>;
enum MSG {
    S(String),
    SKIP
}
type DICT = serde_json::Map<String, serde_json::Value>;

fn current_time() -> TIME {
    SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_secs()
}

macro_rules! ret_ok {
    () => { Ok("{ \"type\":\"ok\" }".into()) };
    ($s:expr) => { Ok(format!("{{ \"type\":\"ok\", {} }}", $s).into()) }
}
fn ret_err<T, S : Into<String>>(code : u16, msg : S) -> Result<T, tide::Error> {
    Err(tide::Error::from_str(code, msg.into()))
}

fn _mpsc_send<S : Into<String>>(host : &ClientInfo, msg : S) -> Result<(), mpsc::SendError<MSG>> {
    host.msgs.0.read().unwrap().send(MSG::S(msg.into()))
}
fn _mpsc_send_skip(host : &ClientInfo) -> Result<(), mpsc::SendError<MSG>> {
    host.msgs.0.read().unwrap().send(MSG::SKIP)
}

async fn parse_req(req : &mut Request<_State>) -> Option<(ID, String, DICT, String)> {
    let ty = req.header("type")?[0].as_str().to_owned();
    let ci = req.header("id")?[0].as_str().parse::<ID>().expect("id is not valid number!");
    let body = req.body_string().await.expect("body is not utf8 string!");
    let body = serde_json::from_str::<serde_json::Value>(&body);
    if let Ok(body) = body {
        if let serde_json::Value::Object(v) = body {
            return Some((ci, ty, v, req.remote().unwrap().to_owned()));
        }
    }
    None
}

fn get_bool<T>(obj : DICT, key : &str) -> Result<bool, Result<T, tide::Error>> {
    match obj.get(key) {
        None => Err(ret_err(400, "key not in body")),
        Some(v) => match v.as_bool() {
            None => Err(ret_err(400, "key value not bool")),
            Some(b) => Ok(b)
        }
    }
}
fn get_str<T>(obj : &DICT, key : &str) -> Result<String, Result<T, tide::Error>> {
    match obj.get(key) {
        None => Err(ret_err(400, "key not in body")),
        Some(v) => match v.as_str() {
            None => Err(ret_err(400, "key value not string")),
            Some(s) => Ok(s.to_owned())
        }
    }
}
fn get_num<T>(obj : &DICT, key : &str) -> Result<ID, Result<T, tide::Error>> {
    match obj.get(key) {
        None => Err(ret_err(400, "key not in body")),
        Some(v) => match v.as_number() {
            None => Err(ret_err(400, "key value not string")),
            Some(s) => match s.as_u64() {
                None => Err(ret_err(400, "key value is not u64")),
                Some(u) => Ok(ID::try_from(u).expect("could not convert number to ID"))
            }
        }
    }
}

#[derive(Debug)]
struct State {
    i_client: ID,
    clients: HashMap<ID, ClientInfo>,
    lobbies: HashMap<String, Lobby>
}
#[derive(Debug)]
struct ClientInfo {
    username: String,
    last_polled: TIME,
    msgs: (RwLock<mpsc::Sender<MSG>>, Mutex<mpsc::Receiver<MSG>>)
}
#[derive(Debug)]
struct Lobby {
    host: ID,
    client: Option<ID>
}

#[tokio::main]
async fn main() -> tide::Result<()> {
    /*let tunnel = ngrok::Session::builder()
        .authtoken("2lKc8ZOXU0GcG0B6z96Y7iM78KR_7dAA5nT9gbfeHVZH5HXA9")
        .connect()
        .await.expect("could not connect to ngrok service!");
    let endpoint = tunnel
        .http_endpoint()
        .domain("equipped-chamois-big.ngrok-free.app")
        .forwards_to("localhost:8000")
        .listen()
        .await.expect("could not listen to ngrok endpoint!");

    println!("ngrok listening on {} => {}", endpoint.forwards_to(), endpoint.url());*/

    let state = State{ i_client: 0, clients: HashMap::new(), lobbies: HashMap::new() };
    let mut app = tide::with_state(Arc::new(RwLock::new(state)));
    //call /hello first thing to register the client
    app.at("/hello").post(req_hello);
    //call /poll periodically. this will block until theres a message or timeout.
    app.at("/poll").get(req_poll);
    //call /post when theres something to tell the matchmaker
    app.at("/post").post(req_post);

    let _ngrok = std::process::Command::new("ngrok")
        .args([ "http", "--domain=equipped-chamois-big.ngrok-free.app", "8000" ])
        .stdout(Stdio::null())
        .spawn()?;

    //let mut listener = tide::listener::ConcurrentListener::new()
    //    .with_listener("localhost:0");
    //listener.listen(app).await?;
    app.listen("localhost:8000").await?;
    Ok(())
}

// curl -X POST -H "type:hello" -d "{ "\""username"\"":"\""foo"\"" }" localhost:8080/hello
async fn req_hello(mut req: Request<_State>) -> tide::Result {
    let (_ci, _ty, body, _remote) = match parse_req(&mut req).await {
        None => return ret_err(400, "malformed request type or body!"),
        Some((ci, _ty, body, remote)) => (ci, _ty, body, remote)
    };
    
    let mut state = req.state().write().unwrap();
    let ci = state.i_client;
    state.i_client += 1;

    let username = match get_str(&body, "username") { Ok(s) => s, Err(e) => return e };
    
    println!("added user {}", username);

    let mpsc = mpsc::channel();

    state.clients.insert(ci, ClientInfo { username, last_polled: current_time(), msgs: (RwLock::new(mpsc.0), Mutex::new(mpsc.1)) });
    ret_ok!(format!("\"id\":{}", ci))
}

async fn req_poll(req: Request<_State>) -> tide::Result {
    let ci = req.header("id").expect("missing id header")[0].as_str().parse::<ID>().expect("id is not valid number!");
    let state = req.state().read().unwrap();
    let client = state.clients.get(&ci).expect("client entry missing!");
    let msg = client.msgs.1.lock().unwrap().recv_timeout(Duration::from_secs(30));
    match msg {
        Ok(s) => match s {
            MSG::S(s) => Ok(s.into()),
            MSG::SKIP => ret_err(204, "no message")
        },
        Err(_) => ret_err(204, "no message")
    }
}

async fn req_post(mut req: Request<_State>) -> tide::Result {
    let (cid, ty, body, _remote) = match parse_req(&mut req).await {
        None => return ret_err(400, "malformed request type or body!"),
        Some(v) => v
    };

    println!("post req {}: {}", cid, ty);

    let state = req.state();
    
    let ret = match ty.as_str() {
        "stop_poll" => _stop_poll(state, cid).await,
        "lobby_new" => _lobby_new(state, cid).await,
        "lobby_list" => _lobby_list(state, cid, body).await,
        "lobby_has" => _lobby_has(state, cid, body).await,
        "lobby_join" => _lobby_join(state, cid, body).await,
        "join_accept" => _join_accept(state, cid, body).await,
        "client_joined" => _client_joined(state, cid, body).await,
        _ => ret_err(400, format!("unknown type {}", ty))
    };

    println!("{} => {:?}", ty, ret);

    ret
}

async fn _stop_poll(state : &_State, cid : ID) -> tide::Result {
    let state = state.read().unwrap();
    let host = state.clients.get(&cid).expect("id invalid");
    
    let msg = "{ \"type\":\"kill_poll\" }";
    if _mpsc_send(host, msg).is_err() {
        return ret_err(500, "could not send message to poll");
    }
    
    ret_ok!()
}

fn _gen_lobby_code() -> String {
    let mut rng = rand::thread_rng();
    (0..4).map(|_| rng.gen_range(b'A'..=b'Z') as char).into_iter().collect()
}

async fn _lobby_new(state : &_State, cid : ID) -> tide::Result {
    let mut state = state.write().unwrap();
    let mut lobby_code = _gen_lobby_code();

    while state.lobbies.contains_key(&lobby_code) {
        lobby_code = _gen_lobby_code();
    }

    state.lobbies.insert(lobby_code.clone(), Lobby { host: cid, client: None });

    ret_ok!(format!("\"lobby_code\":\"{}\"", lobby_code))
}

async fn _lobby_list(state : &_State, _cid : ID, body : DICT) -> tide::Result {
    let state = state.read().unwrap();
    let show_all = match get_bool(body, "all") { Ok(s) => s, Err(e) => return e };

    let lbs = state.lobbies.iter()
        .filter(|(_nm, lb)| show_all || lb.client.is_none());
    let res = lbs.map(|(k, v)| {
        let host = state.clients.get(&v.host).unwrap();
        format!("{{ \"lobby_code\":\"{}\", \"host\":\"{}\" }}", k, host.username)
    });

    ret_ok!(format!("\"lobbies\":[{}]", res.collect::<Vec<String>>().join(", ")))
}

async fn _lobby_has(state : &_State, _cid : ID, body : DICT) -> tide::Result {
    let state = state.read().unwrap();
    let lobby_code = match get_str(&body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    
    let lobby = match state.lobbies.get(&lobby_code) { Some(l) => l, None => 
        return ret_err(404, "lobby does not exist")
    };
    let host = state.clients.get(&lobby.host).expect("host client entry missing");
    if lobby.client.is_some() {
        return ret_err(403, "lobby is full")
    }
    
    ret_ok!(format!("\"host_id\":{}, \"host_name\":{}", lobby.host, host.username))
}

async fn _lobby_join(state : &_State, cid : ID, body : DICT) -> tide::Result {
    let state = state.read().unwrap();
    let lobby_code = match get_str(&body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    let net_info = match get_str(&body, "net_info") { Ok(s) => s, Err(e) => return e };
    
    let lobby = match state.lobbies.get(&lobby_code) { Some(l) => l, None => 
        return ret_err(404, "lobby does not exist")
    };
    if lobby.client.is_some() {
        return ret_err(403, "lobby is full")
    }
    
    let host = state.clients.get(&lobby.host).expect("lobby host id invalid");
    let cname = &state.clients.get(&cid).expect("client entry missing").username;
    
    let msg = format!("{{ \"type\":\"join_request\", \"lobby_code\":\"{}\", \"req_id\":{}, \"req_name\":\"{}\" \"net_info\":{} }}", lobby_code, cid, cname, net_info);
    if _mpsc_send(host, &msg).is_err() {
        return ret_err(500, "could not send message to host");
    }
    
    ret_ok!()
}

async fn _join_accept(state : &_State, _cid : ID, body : DICT) -> tide::Result {
    let state = state.read().unwrap();
    let req_cid = match get_num(&body, "req_id") { Ok(s) => s, Err(e) => return e };
    let net_info = match get_str(&body, "net_info") { Ok(s) => s, Err(e) => return e };
    
    let requestor = state.clients.get(&req_cid).expect("requestor id invalid");
    
    let msg = format!("{{ \"type\":\"host_info\", \"net_info\":{} }}", net_info);
    if _mpsc_send(requestor, &msg).is_err() {
        return ret_err(500, "could not send message to requestor");
    }
    
    ret_ok!()
}

async fn _client_joined(state : &_State, cid : ID, body : DICT) -> tide::Result {
    let mut state = match state.try_write() {
        Ok(w) => w,
        Err(_) => {
            {
                let state = state.read().unwrap();
                let host = state.clients.get(&cid).expect("id invalid");
                if _mpsc_send_skip(host).is_err() {
                    return ret_err(500, "could not send message to poll");
                }
            }
            state.write().unwrap()
        }
    };

    let lobby_code = match get_str(&body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    let client_id = match get_num(&body, "client_id") { Ok(s) => s, Err(e) => return e };
    
    let lobby = match state.lobbies.get_mut(&lobby_code) { Some(l) => l, None => 
        return ret_err(404, "lobby does not exist")
    };
    
    lobby.client = Some(client_id);
    
    ret_ok!()
}

async fn _lobby_leave(state : &_State, _cid : ID, body : DICT) -> tide::Result {
    
    unimplemented!()
}

async fn _lobby_close(state : &_State, _cid : ID, body : DICT) -> tide::Result {
    
    unimplemented!()
}