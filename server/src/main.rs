/*
 * Matchmaker for game lobbies
 * 
 * endpoints:
 *  - POST  /hello { "username"="..." }
 *  - GET   /poll (blocking w/ timeout)
 *  - POST  /post
 * 
 * lobby host:
 *  - /post { type="lobby_new" }  =>  { lobby_code="XXXX" }
 *  - /poll => { type="join_request", net_info="encoded sdp + ice" }
 *  - /post { type="join_accept", net_info="encoded sdp + ice" }
 *  - /post { type="lobby_close" }
 * 
 * lobby client:
 *  - /post { type="lobby_join", lobby_code="XXXX", net_info="encoded sdp + ice" }  =>  { type="fail", reason="...." } OR { type="ok" }
 *  - /poll => { type="host_info", net_info="encoded sdp + ice" }
 *  - /post { type="lobby_leave" }
 */

use std::collections::HashMap;
use std::process::Stdio;
use std::sync::Arc;
use std::sync::mpsc;
use std::time::SystemTime;
use async_std::sync::Mutex;
use async_std::sync::MutexGuard;
use rand::Rng;
use tide::Request;

type ID = u32;
type TIME = u64;
type _State = Arc<Mutex<State>>;

fn current_time() -> TIME {
    SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_secs()
}

fn ret_err<T, S : Into<String>>(code : u16, msg : S) -> Result<T, tide::Error> {
    Err(tide::Error::from_str(code, msg.into()))
}

async fn parse_req(req : &mut Request<_State>) -> Option<(String, serde_json::Map<String, serde_json::Value>, String)> {
    let ty = req.header("type")?[0].as_str().to_owned();
    let body = req.body_string().await.expect("body is not utf8 string!");
    let body = serde_json::from_str::<serde_json::Value>(&body);
    if let Ok(body) = body {
        if let serde_json::Value::Object(v) = body {
            return Some((ty, v, req.remote().unwrap().to_owned()));
        }
    }
    None
}

fn get_bool<T>(obj : serde_json::Map<String, serde_json::Value>, key : &str) -> Result<bool, Result<T, tide::Error>> {
    match obj.get(key) {
        None => return Err(ret_err(400, "key not in body")),
        Some(v) => match v.as_bool() {
            None => return Err(ret_err(400, "key value not bool")),
            Some(b) => Ok(b)
        }
    }
}

fn get_str<T>(obj : serde_json::Map<String, serde_json::Value>, key : &str) -> Result<String, Result<T, tide::Error>> {
    match obj.get(key) {
        None => return Err(ret_err(400, "key not in body")),
        Some(v) => match v.as_str() {
            None => return Err(ret_err(400, "key value not string")),
            Some(s) => Ok(s.to_owned())
        }
    }
}

#[derive(Debug)]
struct State {
    i_client: ID,
    client_addrs: HashMap<String, ID>,
    clients: HashMap<ID, ClientInfo>,
    lobbies: HashMap<String, Lobby>
}

#[derive(Debug)]
struct ClientInfo {
    username: String,
    last_polled: TIME,
    on_conn_info: (mpsc::Sender<i32>, mpsc::Receiver<i32>)
}
#[derive(Debug)]
struct Lobby {
    host: ID,
    has_p2: bool
}

#[async_std::main]
async fn main() -> tide::Result<()> {
    let state = State{ i_client: 0, client_addrs: HashMap::new(), clients: HashMap::new(), lobbies: HashMap::new() };
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

    state.client_addrs.insert(remote, ci);
    state.clients.insert(ci, ClientInfo { username, last_polled: current_time(), on_conn_info: mpsc::channel() });
    Ok(("Hello, ".to_owned() + req.remote().expect("client information unknown!")).into())
}

async fn req_poll(mut _req: Request<_State>) -> tide::Result {
    unimplemented!()
}

async fn req_post(mut req: Request<_State>) -> tide::Result {
    let (ty, body, remote) = match parse_req(&mut req).await {
        None => return ret_err(400, "malformed request type or body!"),
        Some((_ty, body, remote)) => (_ty, body, remote)
    };
    let state = req.state().lock().await;

    let cid = *state.client_addrs.get(&remote).expect("client not registered with /hello yet!");
    
    match ty.as_str() {
        "lobby_new" => _lobby_new(state, cid).await,
        "lobby_list" => _lobby_list(state, cid, body).await,
        _ => return ret_err(400, format!("unknown type {}", ty))
    }
}

fn _gen_lobby_code() -> String {
    let mut rng = rand::thread_rng();
    (0..4).map(|_| rng.gen_range(b'A', b'Z' + 1) as char ).into_iter().collect()
}

async fn _lobby_new(mut state : MutexGuard<'_, State>, cid : u32) -> tide::Result {
    let mut lobby_code = _gen_lobby_code();

    while state.lobbies.contains_key(&lobby_code) {
        lobby_code = _gen_lobby_code();
    }

    state.lobbies.insert(lobby_code.clone(), Lobby { host: cid, has_p2: false });

    Ok(format!(" \"lobby_code\":\"{}\" ", lobby_code).into())
}

async fn _lobby_list(state : MutexGuard<'_, State>, _cid : u32, body : serde_json::Map<String, serde_json::Value>) -> tide::Result {
    let show_all = match get_bool(body, "all") { Ok(s) => s, Err(e) => return e };

    let lbs = state.lobbies.iter()
        .filter(|l| show_all || !l.1.has_p2);
    let res = lbs.map(|(k, v)| {
        let host = state.clients.get(&v.host).unwrap();
        format!("{{ \"lobby_code\":\"{}\", \"host\":\"{}\" }}", k, host.username)
    });

    Ok(format!(" \"lobbies\":[{}] ", res.collect::<Vec<String>>().join(", ")).into())
}