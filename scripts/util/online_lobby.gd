class_name OnlineLobby extends Node

signal on_p2_init_connect(nm : String)
signal on_p2_connect_fail
signal on_chat_msg(msg : String)
signal on_broadcast(msg : String)
signal on_lobby_err(msg : String)

static var debug_network = true

enum STATE {
	NO_INIT, MENU, LOBBY, PRE_GAME, GAME, POST_GAME
}

class PeerNetInfo:
	var sdp : String
	var ices = []
	var peer : WebRTCPeerConnection

	func _init(peer : WebRTCPeerConnection):
		var me = self
		self.peer = peer
		peer.session_description_created.connect(func (type: String, sdp: String):
			me.sdp = sdp
		)
		
		peer.ice_candidate_created.connect(func (media: String, index: int, name: String):
			me.ices.push_back([media, str(index), name])
		)
	
	func get_info():
		while true:
			if sdp and peer.get_gathering_state() == WebRTCPeerConnection.GATHERING_STATE_COMPLETE:
				print_debug("using sdp:\n", sdp, "\nusing ice:\n", ices)
				return [ sdp, ices ]
			await GameMaster.get_timer(0.1).timeout

class PlayerInfo:
	var mm_id : int
	var mp_id : int = -1
	var nm : String
	var rdy : bool
	var chara_id : int = 2
	var input_ty : String = "pad"
	var input_source : InputMan.PlayerInput
	func _init(id, nm):
		self.mm_id = id
		self.nm = nm

class LobbyInfo:
	signal on_p2
	
	var code : String
	var is_p2 : bool
	var p1 : PlayerInfo
	var p2 : PlayerInfo


static func enc_net(info):
	return Marshalls.utf8_to_base64(info[0] + char(1) + "\n".join(info[1].map(func (v): return char(2).join(v))))
static func dec_net(s):
	var res = Marshalls.base64_to_utf8(s).split(char(1))
	return [res[0], Array(res[1].split("\n")).map(func (v): return v.split(char(2)))]


signal request_done

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

static func _init_http(client : HTTPClient, block):
	client.blocking_mode_enabled = block
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

static func _post(url : String, body : Dictionary):
	while busy:
		await signals.request_done
	busy = true
	var headers = PackedStringArray([
		"ngrok-skip-browser-warning: 69420",
		"Client_id: " + str(my_info.mm_id if my_info else 0)
	])
	http_poster.request(HTTPClient.METHOD_POST, url, headers, JSON.stringify(body))
	
	var st = http_poster.get_status()
	while st == HTTPClient.STATUS_REQUESTING:
		await GameMaster.get_timer(0.1).timeout
		http_poster.poll()
		st = http_poster.get_status()
	
	if st != HTTPClient.STATUS_BODY:
		return null
	
	var code = http_poster.get_response_code()
	var response = PackedByteArray()
	while http_poster.get_status() == HTTPClient.STATUS_BODY:
		var chunk = http_poster.read_response_body_chunk()
		if chunk.is_empty():
			break
		response.append_array(chunk)
	
	var sres = response.get_string_from_utf8()
	var json = null
	if sres.begins_with("<!DOCTYPE html>"):
		print_debug("html returned (code %d), probably an ngrok error!" % code)
		sres = ""
	else:
		json = JSON.parse_string(sres)
		print_debug("post success (", code, "): ", sres)
	
	busy = false
	signals.request_done.emit()
	
	return {
		"code": code,
		"body": json if json else {},
		"body_raw": sres
	}

static func _poll():
	var headers = PackedStringArray([
		"ngrok-skip-browser-warning: 69420",
		"Client_id: " + str(my_info.mm_id)
	])
	http_poller.request(HTTPClient.METHOD_GET, "/poll", headers)
	var st = http_poller.get_status()
	while st == HTTPClient.STATUS_REQUESTING:
		await GameMaster.get_timer(0.1).timeout
		http_poller.poll()
		st = http_poller.get_status()
	
	if st == HTTPClient.STATUS_CONNECTED:
		return { "code": 504, "body": {}, "body_raw": "" }
	elif st != HTTPClient.STATUS_BODY:
		return null
	
	var code = http_poller.get_response_code()
	var response = PackedByteArray()
	while http_poller.get_status() == HTTPClient.STATUS_BODY:
		var chunk = http_poller.read_response_body_chunk()
		if chunk.is_empty():
			break
		response.append_array(chunk)
	
	var sres = response.get_string_from_utf8()
	#http_poller.get_response_headers_as_dictionary().get("Content-type")
	#just let it fail if is not json
	var json = JSON.parse_string(sres)
	
	return {
		"code": code,
		"body": json if json else {},
		"body_raw": sres
	}


static func init(usrnm : String):
	assert(state == STATE.NO_INIT)
	
	signals = new()
	listeners["join_request"] = OnlineLobby._on_join_req
	
	http_poster = HTTPClient.new()
	http_poller = HTTPClient.new()
	
	var res = await _init_http(http_poster, true)
	if !res: return false
	
	res = await _init_http(http_poller, false)
	if !res: return false
	
	res = await _post("/hello", { "username": usrnm })
	var body = res.body
	if res.code != 200:
		print_debug("hello failed: ", res.code, res.body_raw)
		return false
	
	my_info = PlayerInfo.new(body["id"], usrnm)
	my_info.input_source = InputMan.get_player_input(0)
	
	rtc = WebRTCMultiplayerPeer.new()
	#rtc.peer_connected.connect(signals._on_peer_conn)
	#rtc.peer_disconnected.connect(signals._on_peer_dconn)
	
	GameMaster.root_node.add_child(signals)
	
	signals.multiplayer.peer_connected.connect(signals._on_peer_conn)
	signals.multiplayer.peer_disconnected.connect(signals._on_peer_dconn)
	
	state = STATE.MENU
	
	print_debug(listeners.get("join_request"))
	
	return true

static func create():
	assert(state == STATE.MENU)
	
	var res = await _post("/lobby_new", {})
	if res.code != 200:
		print_debug("create lobby fail: ", res.body_raw)
		return null
	
	my_info.mp_id = 1
	rtc.create_mesh(1)
	
	lobby = LobbyInfo.new()
	lobby.code = res.body["lobby_code"]
	lobby.p1 = my_info
	
	state = STATE.LOBBY
	
	return lobby

static func join(code):
	assert(state == STATE.MENU)
	
	var res = await _post("/lobby_has", { "lobby_code": code })
	if res.code != 200:
		print_debug("check lobby fail: ", res.body_raw)
		return null
	
	var host_id = res.body["host_id"]
	var host_name = res.body["host_name"]
	
	my_info.mp_id = 2
	rtc.create_mesh(2)
	
	var peer := WebRTCPeerConnection.new()
	assert(!peer.initialize(NetUtil.get_ice_servers()))
	
	assert(!rtc.add_peer(peer, 1))
	
	var peer_info = PeerNetInfo.new(peer)
	
	assert(!peer.create_offer())
	
	signals.multiplayer.multiplayer_peer = rtc
	
	var my_net_info = await peer_info.get_info()
	if not my_net_info:
		print_debug("could not generate peer sdp / ice!")
		return null
	
	assert(!peer.set_local_description("offer", my_net_info[0]))
	
	res = await _post("/lobby_join", {
		"lobby_code": code, "net_info": enc_net(my_net_info)
	})
	if res.code != 200:
		print_debug("join lobby fail: ", res.body_raw)
		return null
	
	for i in range(11):
		if i == 10:
			print_debug("lobby host did not reply!")
			return null
		if unhandled_msgs.has("host_info"):
			break
		await GameMaster.get_timer(1.0).timeout
	
	var host_info = unhandled_msgs.get("host_info")
	unhandled_msgs.erase("host_info")
	
	var net_info = dec_net(host_info["net_info"])
	
	_next_connd_peer = -1
	
	assert(!peer.set_remote_description("answer", net_info[0]))
	for s in net_info[1]:
		peer.add_ice_candidate(s[0], int(s[1]), s[2])
	
	for i in range(21):
		if _next_connd_peer > -1:
			break
		if i == 10:
			print_debug("connection timeout!")
			return null
		await GameMaster.get_timer(0.5).timeout
	
	lobby = LobbyInfo.new()
	lobby.code = code
	lobby.p1 = PlayerInfo.new(host_id, host_name)
	lobby.p1.mp_id = 1
	lobby.p2 = my_info
	lobby.is_p2 = true
	
	state = STATE.LOBBY
	
	return lobby

static var _next_connd_peer = -1
func _on_peer_conn(i):
	_next_connd_peer = i
	print_debug("player connected: ID ", i)
	print_debug("current peers: ", multiplayer.get_peers())

func _on_peer_dconn(i):
	if state == STATE.LOBBY:
		if lobby.is_p2:
			lobby.is_p2 = false
			lobby.p1 = my_info
			print_debug("player 1 (ID %d) disconnected, you are now host" % i)
		else:
			print_debug("player 2 (ID %d) disconnected" % i)
		lobby.p2 = null
		var res = await OnlineLobby._post("/host_left" if lobby.is_p2 else "/client_left", {
			"lobby_code": lobby.code
		})
		if res.code != 200:
			print_debug("failed to inform disconnect")
			return

static func _on_join_req(body : Dictionary):
	var req_id = body["req_id"]
	var req_name = body["req_name"]
	var net_info = dec_net(body["net_info"])
	var lobby_code = body["lobby_code"]
	
	signals.on_p2_init_connect.emit(req_name)
	
	var peer := WebRTCPeerConnection.new()
	assert(!peer.initialize(NetUtil.get_ice_servers()))
	
	var peer_info = PeerNetInfo.new(peer)
	
	assert(!rtc.add_peer(peer, 2))
	assert(!peer.set_remote_description("offer", net_info[0]))
	for s in net_info[1]:
		peer.add_ice_candidate(s[0], int(s[1]), s[2])
	
	signals.multiplayer.multiplayer_peer = rtc
	
	var my_net_info = await peer_info.get_info()
	if not my_net_info:
		print_debug("could not generate peer sdp / ice!")
		signals.on_p2_connect_fail.emit()
		return false
	
	assert(!peer.set_local_description("answer", my_net_info[0]))
	
	_next_connd_peer = -1
	
	var res = await _post("/join_accept", {
		"req_id": req_id, "net_info": enc_net(my_net_info)
	})
	if res.code != 200:
		print_debug("accept join fail: ", res.body_raw)
		signals.on_p2_connect_fail.emit()
		return
	
	for i in range(11):
		if _next_connd_peer > -1:
			break
		if i == 10:
			print_debug("connection timeout!")
			signals.on_p2_connect_fail.emit()
			return
		await GameMaster.get_timer(0.5).timeout
	
	res = await _post("/client_joined", {
		"lobby_code": lobby_code, "client_id": req_id
	})
	if res.code != 200:
		print_debug("client joined fail: ", res.body_raw)
		signals.on_p2_connect_fail.emit()
		return
	
	lobby.p2 = PlayerInfo.new(req_id, req_name)
	lobby.p2.mp_id = 2
	lobby.on_p2.emit(lobby.p2)

static func start_polling_loop():
	poll = true
	while poll:
		var res = await _poll()
		if not res:
			poll = false
			return
		if res.code == 504:
			await GameMaster.get_timer(0.5).timeout
		else:
			if res.code == 200:
				print_debug("poll msg: ", res.body_raw)
				var ty = res.body.get("type")
				var lis = listeners.get(ty)
				if lis:
					lis.call(res.body)
				else:
					#signals.unhandled_event.emit(res.body)
					unhandled_msgs[ty] = res.body
					
			else:
				print_debug("polling returned error (", res.code, "): ", res.body_raw)
				poll = false
				return

static func leave_lobby():
	assert(state == STATE.LOBBY)
	
	rtc.close()
	
	state = STATE.MENU
	pass

static func player_ready(b : bool):
	assert(state == STATE.LOBBY)
	if lobby and lobby.p2:
		signals._on_ppl_rdy.rpc(b)

static func game_loaded():
	if lobby:
		assert(state == STATE.PRE_GAME)
		signals._on_game_loaded.rpc()

signal on_ppl_rdy(id, b)

@rpc("any_peer", "call_local")
func _on_ppl_rdy(b):
	var id = multiplayer.get_remote_sender_id()
	print_debug("player ", id, " ready: ", b)
	if id == lobby.p1.mp_id:
		lobby.p1.rdy = b
	else:
		lobby.p2.rdy = b
	
	on_ppl_rdy.emit(id, b)
	
	if lobby.p1.rdy and lobby.p2.rdy and not lobby.is_p2:
		broadcast("starting game... 3")
		await GameMaster.get_timer(1.0).timeout
		broadcast("starting game... 2")
		await GameMaster.get_timer(1.0).timeout
		broadcast("starting game... 1")
		await GameMaster.get_timer(1.0).timeout
		_start_game.rpc()

@rpc("authority", "call_local")
func _start_game():
	state = STATE.PRE_GAME
	_n_game_loaded = 0
	SceneMan.load_scene(SceneMan.GAME)
	GameMaster.new_match(2, 2, _GameNetBase.TY.ONLINE)

var _n_game_loaded = 0

@rpc("any_peer", "call_local")
func _on_game_loaded():
	var p = multiplayer.get_remote_sender_id()
	print_debug("player ", p, " loaded")
	_n_game_loaded += 1
	
	if _n_game_loaded == 2:
		state = STATE.GAME
		if not lobby.is_p2:
			print_debug("(host) everyone loaded, starting sync")
			GameMaster.net_master.start()

static func send_chat(msg):
	signals._recv_chat.rpc(msg)

@rpc("any_peer")
func _recv_chat(msg):
	signals.on_chat_msg.emit(msg)

static func broadcast(msg):
	signals._broadcasted.rpc(msg)

@rpc("any_peer", "call_local")
func _broadcasted(msg):
	signals.on_broadcast.emit(msg)
