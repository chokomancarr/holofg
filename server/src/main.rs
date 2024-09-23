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
use std::sync::mpsc;
use std::time::SystemTime;
use async_std::sync::Mutex;
use async_std::sync::MutexGuard;
use std::convert::TryFrom;
use rand::Rng;
use tide::Request;

type ID = u32;
type TIME = u64;
type _State = Arc<Mutex<State>>;
type MSG = String;
type DICT = serde_json::Map<String, serde_json::Value>;

fn current_time() -> TIME {
    SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_secs()
}

macro_rules! ret_ok {
    () => Ok("{ \"type\":\"ok\" }".into()),
    ($s:expr) => Ok(format!("{{ \"type\":\"ok\", {} }}", $s).into())
}
fn ret_err<T, S : Into<String>>(code : u16, msg : S) -> Result<T, tide::Error> {
    Err(tide::Error::from_str(code, msg.into()))
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
fn get_str<T>(obj : DICT, key : &str) -> Result<String, Result<T, tide::Error>> {
    match obj.get(key) {
        None => Err(ret_err(400, "key not in body")),
        Some(v) => match v.as_str() {
            None => Err(ret_err(400, "key value not string")),
            Some(s) => Ok(s.to_owned())
        }
    }
}
fn get_num<T>(obj : DICT, key : &str) -> Result<u64, Result<T, tide::Error>> {
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
    msgs: (mpsc::Sender<MSG>, mpsc::Receiver<MSG>)
}
#[derive(Debug)]
struct Lobby {
    host: ID,
    client: Option<ID>
}

#[async_std::main]
async fn main() -> tide::Result<()> {
    let state = State{ i_client: 0, clients: HashMap::new(), lobbies: HashMap::new() };
    let mut app = tide::with_state(Arc::new(Mutex::new(state)));
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
    let (_ty, body, remote) = match parse_req(&mut req).await {
        None => return ret_err(400, "malformed request type or body!"),
        Some((_ty, body, remote)) => (_ty, body, remote)
    };
    
    let mut state = req.state().lock().await;
    let ci = state.i_client;
    state.i_client += 1;

    let username = match get_str(body, "username") { Ok(s) => s, Err(e) => return e };
    
    println!("added user {}", username);

    state.clients.insert(ci, ClientInfo { username, last_polled: current_time(), msgs: mpsc::channel() });
    ret_ok!(format!("\"id\":{}", ci))
}

fn _get_recver(ci : ID, state : &_State) {
    let state = state.lock().await;
    let client = state.clients.get(&ci).expect("client entry missing!");
    
    //release the lock while waiting for message
    client.msgs.0.clone()
}

async fn req_poll(_req: Request<_State>) -> tide::Result {
    let ci = req.header("id")?[0].as_str().parse::<ID>().expect("id is not valid number!");
    let recver = _get_recver(ci, req.state()).await.unwrap();
    let msg = recver.recv_timeout(Duration::from_secs(30)).await;
    match msg {
        Ok(s) => Ok(s.into())
        Err(_) => ret_err(204, "no message");
    }
}

async fn req_post(mut req: Request<_State>) -> tide::Result {
    let (cid, ty, body, remote) = match parse_req(&mut req).await {
        None => return ret_err(400, "malformed request type or body!"),
        Some(v) => v
    };
    let state = req.state().lock().await;

    let client = state.clients.get(&cid).expect("client entry missing!");
    
    println!("post req {}: {}", cid, ty);
    
    match ty.as_str() {
        "stop_poll" => _stop_poll(state, cid).await,
        "lobby_new" => _lobby_new(state, cid).await,
        "lobby_list" => _lobby_list(state, cid, body).await,
        "lobby_has" => _lobby_has(state, cid, body).await,
        "lobby_join" => _lobby_join(state, cid, body).await,
        "join_accept" => _join_accept(state, cid, body).await,
        "client_joined" => _client_joined(state, cid, body).await,
        _ => return ret_err(400, format!("unknown type {}", ty))
    }
}

async fn _stop_poll(state : MutexGuard<State>, cid : ID) -> tide::Result {
    let host = state.clients.get(&cid).expect("id invalid");
    
    let msg = "{ \"type\":\"kill_poll\" }";
    if host.msgs.1.send(msg).is_error() {
        return ret_err(500, "could not send message to poll");
    }
    
    ret_ok!()
}

fn _gen_lobby_code() -> String {
    let mut rng = rand::thread_rng();
    (0..4).map(|_| rng.gen_range(b'A', b'Z' + 1) as char).into_iter().collect()
}

async fn _lobby_new(mut state : MutexGuard<'_, State>, cid : ID) -> tide::Result {
    let mut lobby_code = _gen_lobby_code();

    while state.lobbies.contains_key(&lobby_code) {
        lobby_code = _gen_lobby_code();
    }

    state.lobbies.insert(lobby_code.clone(), Lobby { host: cid, client: None });

    ret_ok!(format!("\"lobby_code\":\"{}\"", lobby_code))
}

async fn _lobby_list(state : MutexGuard<'_, State>, _cid : ID, body : DICT) -> tide::Result {
    let show_all = match get_bool(body, "all") { Ok(s) => s, Err(e) => return e };

    let lbs = state.lobbies.iter()
        .filter(|l| show_all || l.1.is_none());
    let res = lbs.map(|(k, v)| {
        let host = state.clients.get(&v.host).unwrap();
        format!("{{ \"lobby_code\":\"{}\", \"host\":\"{}\" }}", k, host.username)
    });

    ret_ok!(format!("\"lobbies\":[{}]", res.collect::<Vec<String>>().join(", ")))
}

async fn _lobby_has(state : MutexGuard<'_, State>, cid : ID, body : DICT) -> tide::Result {
    let lobby_code = match get_str(body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    
    let lobby = match state.lobbies.get(&lobby_code) { Some(l) => l, None => 
        return ret_err(404, "lobby does not exist")
    };
    let host = match state.clients.get(&lobby.host).expect("host client entry missing");
    if lobby.is_some() {
        return ret_err(403, "lobby is full")
    }
    
    ret_ok!(format!("\"host_id\":{}", lobby.host, host.username))
}

async fn _lobby_join(state : MutexGuard<'_, State>, cid : ID, body : DICT) -> tide::Result {
    let lobby_code = match get_str(body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    let net_info = match get_str(body, "net_info") { Ok(s) => s, Err(e) => return e };
    
    let lobby = match state.lobbies.get(&lobby_code) { Some(l) => l, None => 
        return ret_err(404, "lobby does not exist")
    };
    if lobby.is_some() {
        return ret_err(403, "lobby is full")
    }
    
    let host = state.clients.get(&lobby.host).expect("lobby host id invalid");
    let cname = state.clients.get(&cid).expect("client entry missing").username;
    
    let msg = format!("{{ \"type\":\"join_request\", \"lobby_code\":\"{}\", \"req_id\":{}, \"req_name\":\"{}\" \"net_info\":{} }}", lobby_code, cid, cname, net_info);
    if host.msgs.1.send(msg).is_error() {
        return ret_err(500, "could not send message to host");
    }
    
    ret_ok!()
}

async fn _join_accept(state : MutexGuard<'_, State>, _cid : ID, body : DICT) -> tide::Result {
    let req_cid = match get_num(body, "req_id") { Ok(s) => s, Err(e) => return e };
    let net_info = match get_str(body, "net_info") { Ok(s) => s, Err(e) => return e };
    
    let requestor = state.clients.get(&req_cid).expect("requestor id invalid");
    
    let msg = format!("{{ \"type\":\"host_info\", \"net_info\":{} }}", net_info);
    if requestor.msgs.1.send(msg).is_error() {
        return ret_err(500, "could not send message to requestor");
    }
    
    ret_ok!()
}

async fn _client_joined(mut state : MutexGuard<'_, State>, _cid : ID, body : DICT) -> tide::Result {
    let lobby_code = match get_str(body, "lobby_code") { Ok(s) => s, Err(e) => return e };
    let client_id = match get_num(body, "client_id") { Ok(s) => s, Err(e) => return e };
    
    let mut lobby = match state.lobbies.get_mut(&lobby_code) { Some(l) => l, None => 
        return ret_err(404, "lobby does not exist")
    };
    
    lobby.client = Some(client_id);
    
    ret_ok!()
}

async fn _lobby_leave(state : MutexGuard<'_, State>, _cid : ID, body : DICT) -> tide::Result {
    
    unimplemented!()
}

async fn _lobby_close(state : MutexGuard<'_, State>, _cid : ID, body : DICT) -> tide::Result {
    
    unimplemented!()
}