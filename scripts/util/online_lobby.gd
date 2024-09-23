class_name OnlineLobby extends Node

enum STATE {
	NO_INIT, MENU, LOBBY_WAIT, LOBBY_FULL, PRE_GAME, GAME, POST_GAME
}

class PeerNetInfo:
	var sdp : String
	var ices = []

	func _init(peer : WebRTCPeerConnection):
		var me = self
		peer.session_description_created.connect(func (type: String, sdp: String):
			me.sdp = sdp
		)
		
		peer.ice_candidate_created.connect(func (media: String, index: int, name: String):
			me.ices.push_back(name)
		)
	
	async func get_info():
		for i in range(30):
			if sdp and ices.size() >= 3:
				return [ sdp, ices ]
			await GameMaster.get_timer(0.1).timeout
		if sdp and ices.size() > 0:
			return [ sdp, ices ]

class PlayerInfo:
	var id : int,
	var nm : String,
	var rdy : bool
	func _init(id, nm):
		self.id = id
		self.nm = nm

class LobbyInfo:
	signal on_p2
	
	var code : String,
	var is_p2 : bool,
	var p1 : PlayerInfo,
	var p2 : PlayerInfo


func enc_net(info):
	return Marshalls.utf8_to_base64(info[0] + "\x01" + "\n".join(info[1]))
func dec_net(s):
	var res = Marshalls.base64_to_utf8(s).split("\x01")
	return [res[0], res[1].split("\n")]


signal request_done
#signal unhandled_event(obj : Dictionary)

static var state = STATE.NO_INIT
static var signals : OnlineLobby

static var my_info : PlayerInfo

static var http_poster : HTTPClient
static var http_poller : HTTPClient
static var busy = false
static var poll = false

static var rtc : WebRTCMultiplayerPeer

static var lobby : LobbyInfo

static var listeners : Dictionary = {}
static var unhandled_msgs : Dictionary = {}

func process():
	if rtc:
		rtc.poll()

static func _init_http(client : HTTPClient):
	client.blocking_mode_enabled = true
	if client.connect_to_host("https://equipped-chamois-big.ngrok-free.app") != OK:
		print_debug("could not connect to host!")
		return false
	
	while true:
		await GameMaster.get_timer(0.1).timeout
		client.poll()
		var st = client.get_status()
		if st != HTTPClient.STATUS_RESOLVING and st != HTTPClient.STATUS_CONNECTING:
			if st == HTTPClient.STATUS_CONNECTED:
				return true
			else:
				print_debug("connect to host failed with error ", st)
				return false

static func _post(url : String, ty : String, body : Dictionary):
	while busy:
		await signals.request_done
	busy = true
	var headers = PackedStringArray(["ngrok-skip-browser-warning: 69420", "type: " + ty])
	http_poster.request(HTTPClient.METHOD_POST, url, headers, JSON.stringify(body))
	
	while not http_poster.has_response():
		http_poster.poll()
		await GameMaster.get_timer(0.5).timeout
	
	var code = http_poster.get_response_code()
	var response = PackedByteArray()
	while true:
		var chunk = http_poster.read_response_body_chunk()
		if chunk.is_empty():
			break
		response.append_array(chunk)
	
	var sres = response.get_string_from_utf8()
	var json = JSON.parse_string(sres)
	
	busy = false
	signals.request_done.emit()
	
	return {
		"code": code,
		"body": json if json else {},
		"body_raw": sres
	}

static func _poll():
	var headers = PackedStringArray(["ngrok-skip-browser-warning: 69420"])
	http_poller.request(HTTPClient.METHOD_GET, "/poll", headers)
	
	while not http_poller.has_response():
		http_poller.poll()
		await GameMaster.get_timer(0.5).timeout
	
	var code = http_poller.get_response_code()
	var response = PackedByteArray()
	while true:
		var chunk = http_poller.read_response_body_chunk()
		if chunk.is_empty():
			break
		response.append_array(chunk)
	
	var sres = response.get_string_from_utf8()
	var json = JSON.parse_string(sres)
	
	return {
		"code": code,
		"body": json if json else {},
		"body_raw": sres
	}


static func init(usrnm : String):
	assert(state == STATE.NO_INIT)
	
	http_poster = HTTPClient.new()
	http_poller = HTTPClient.new()
	
	var res = await _init_http(http_poster)
	if !res: return false
	
	res = await _init_http(http_poller)
	if !res: return false
	
	res = await _post("/hello", "hello", { "username": usrnm })
	var body = JSON.stringify(res.body)
	if res.code != 200:
		print_debug("hello failed: ", res.code, body)
		return false
	
	my_info = PlayerInfo.new(body["id"], usrnm)
	
	rtc = WebRTCMultiplayerPeer.new()
	rtc.peer_connected.connect(_on_peer_conn)
	rtc.peer_disconnected.connect(_on_peer_dconn)
	
	signals = new()
	signals.listeners["join_request"] = _on_join_req
	
	GameMaster.root_node.add_child(signals)
	
	state = STATE.MENU
	
	return true

static func create():
	assert(state == STATE.MENU)
	
	var res = await _post("/post", "lobby_new", { "id": my_info.id })
	if res.code != 200:
		print_debug("create lobby fail: ", res.body_raw)
		return null
	
	rtc.create_mesh(my_info.id)
	
	lobby = LobbyInfo.new()
	lobby.code = res["lobby_code"]
	lobby.p1 = my_info
	
	state = STATE.LOBBY_WAIT
	
	return lobby

static func join(code):
	assert(state == STATE.MENU)
	
	var res = await _post("/post", "lobby_has", { "id": my_info.id, "lobby_code": code })
	if res.code != 200:
		print_debug("check lobby fail: ", res.body_raw)
		return false
	
	var host_id = res["host_id"]
	var host_name = res["host_name"]
	
	rtc.create_mesh(my_info.id)
	
	var peer := WebRTCPeerConnection.new()
	assert(!peer.initialize(NetUtil.get_ice_servers()))
	
	assert(!mp.add_peer(peer, host_id))
	
	var peer_info = PeerNetInfo.new(peer)
	
	assert(!peer.create_offer())
	
	multiplayer.multiplayer_peer = mp
	
	var my_net_info = await peer_info.get_info()
	if not my_net_info:
		print_debug("could not generate peer sdp / ice!")
		return false
	
	assert(!peer.set_local_description("offer", my_net_info[0]))
	
	var res = await _post("/post", "lobby_join", {
		"id": my_info.id, "lobby_code": code, "net_info": enc_net(my_net_info)
	})
	if res.code != 200:
		print_debug("join lobby fail: ", res.body_raw)
		return false
	
	for i in range(11):
		if i == 10:
			print_debug("lobby host did not reply!")
			return false
		if unhandled_msgs.has("host_info"):
			break
		await GameMaster.get_timer(1.0).timeout
	
	var host_info = unhandled_msgs.get("host_info")
	unhandled_msgs.erase("host_info")
	
	var net_info = dec_net(host_info["net_info"])
	
	_next_connd_peer = -1
	
	assert(!peer.set_remote_description("answer", net_info[0]))
	for s in net_info[1].split("\n"):
		peer.add_ice_candidate("0", 0, s)
	
	for i in range(11):
		if _next_connd_peer > -1:
			break
		if i == 10:
			print_debug("connection timeout!")
			return false
		await GameMaster.get_timer(0.5).timeout
	
	lobby = LobbyInfo.new()
	lobby.code = lobby_code
	lobby.p1 = PlayerInfo.new(host_id, host_name)
	lobby.p2 = my_info
	lobby.is_p2 = true
	
	return true

static func _next_connd_peer = -1
static func _on_peer_conn(i):
	_next_connd_peer = i

static func _on_peer_dconn(i):
	pass


static func _on_join_req(body : Dictionary):
	var req_id = body["req_id"]
	var req_name = body["req_name"]
	var net_info = dec_net(body["net_info"])
	var lobby_code = body["lobby_code"]
	
	var peer := WebRTCPeerConnection.new()
	assert(!peer.initialize(NetUtil.get_ice_servers()))
	
	var peer_info = PeerNetInfo.new(peer)
	
	assert(!mp.add_peer(peer, req_id))
	assert(!peer.set_remote_description("offer", net_info[0]))
	for s in net_info[1]:
		peer.add_ice_candidate("0", 0, s)
	
	multiplayer.multiplayer_peer = mp
	
	var my_net_info = await peer_info.get_info()
	if not my_net_info:
		print_debug("could not generate peer sdp / ice!")
		return false
	
	assert(!peer.set_local_description("answer", my_net_info[0]))
	
	_next_connd_peer = -1
	
	var res = await _post("/post", "join_accept", {
		"id": my_info.id, "req_id": req_id, "net_info": enc_net(my_net_info)
	})
	if res.code != 200:
		print_debug("accept join fail: ", res.body_raw)
		return
	
	for i in range(11):
		if _next_connd_peer > -1:
			break
		if i == 10:
			print_debug("connection timeout!")
			return
		await GameMaster.get_timer(0.5).timeout
	
	var res = await _post("/post", "client_joined", {
		"id": my_info.id, "lobby_code": lobby_code, "my_info.id": req_id
	})
	if res.code != 200:
		print_debug("accept join fail: ", res.body_raw)
	
	lobby.p2 = PlayerInfo.new(req_id, req_name)
	lobby.on_p2.emit(lobby.p2)

static func start_polling_loop():
	poll = true
	while poll:
		var res = await _poll()
		if res.code == 504:
			await GameMaster.get_timer(0.5).timeout
		else:
			if res.code == 200:
				var ty = res.body.get("type")
				var lis = listeners.get(ty)
				if lis:
					lis.call(res.body)
				else:
					#signals.unhandled_event.emit(res.body)
					unhandled_msgs[ty] = res.body
					
			else:
				print_debug("polling returned error: ", res.code, JSON.stringify(res.body))
				poll = false
				return


static func player_ready(b : bool):
	if lobby and lobby.p2:
		signals._on_ppl_rdy.rpc(b)

@rpc("any_peer", "call_local")
func _on_ppl_rdy(b):
	var id = multiplayer.get_remote_sender_id()
	if id == lobby.p1.id:
		lobby.p1.rdy = b
	else:
		lobby.p2.rdy = b
	
	if lobby.p1.rdy and lobby.p2.rdy and not lobby.is_p2:
		print_debug("starting game...")
		pass