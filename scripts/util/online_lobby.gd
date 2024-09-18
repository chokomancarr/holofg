class_name OnlineLobby

class MMConnection extends Node:
	var server_ip = null
	var server_port = null
	var socket : PacketPeerUDP
	
	var listeners : Dictionary
	
	var unhandled_msgs : Dictionary
	
	static var _instance : MMConnection
	
	func _init(ip, port, sock):
		_instance = self
		server_ip = ip
		server_port = port
		socket = sock
	
	func _process(delta):
		while socket.get_available_packet_count() > 0:
			var msg = await socket.get_packet().get_string_from_ascii()
			var sig = msg.substr(0, 4)
			var body = JSON.parse_string(msg.substr(4))
			if not body:
				body = {}
			var f = listeners.get(sig)
			if f:
				f.call(body)
			else:
				unhandled_msgs[sig] = msg
	
	func try_msg(sig):
		if unhandled_msgs.has(sig):
			return unhandled_msgs[sig]
		else:
			return null

	func try_msg_timeout(sig, t0 = 0.5, nt = 5.0):
		var t = 0
		while true:
			await GameMaster.get_timer(t0).timeout
			var res = try_msg(sig)
			if res:
				return res
			else:
				t += t0
				if t >= nt:
					return null
	
	func send(sig, obj):
		socket.put_packet(sig + JSON.stringify(obj, "", false))

class LobbyInfo extends Node:
	var is_host : bool
	var net : ENetMultiplayerPeer
	var lobby_code : String
	
	var polling_conn : ENetConnection
	
	static var _instance : LobbyInfo
	
	func _init():
		_instance = self
		net = ENetMultiplayerPeer.new()
		multiplayer.multiplayer_peer = net
	
	func _process(_dt):
		if polling_conn:
			var res = polling_conn.service()
			var status = res[0]
			if status == ENetConnection.EVENT_CONNECT:
				var peer = res[1] as ENetPacketPeer
				print_debug("peer connected from port " + str(peer.get_remote_port()))
				net.add_mesh_peer(2 if is_host else 1, polling_conn)
				polling_conn = null
	
	static func new_host():
		var res = new()
		res.is_host = true
		res.net.create_mesh(1)
		
		MMConnection._instance.send("SERV", {})
		var ok = await MMConnection._instance.try_msg_timeout("SVOK")
		if not ok or not ok.get("lobby_code") is String:
			print_debug("invalid SVOK response!")
			return
		res.lobby_code = ok.code
		MMConnection._instance.listeners["CLRQ"] = _on_client_requested
		
		GameMaster.root_node.add_child(res)
		return res
	
	static func new_client(code : String):
		var res = new()
		res.is_host = false
		res.net.create_mesh(2)
		
		var sock = PacketPeerUDP.new()
		sock.bind(0)
		var addr = await NetUtil.request_stun(sock)
		sock.close()
		
		MMConnection._instance.send("CONN", { "code": code,  "client_ip": addr[0], "client_port": int(addr[1]) })
		var ok = await MMConnection._instance.try_msg_timeout("CNOK")
		if not ok or\
			not ok.get("host_ip") is String or\
			not ok.get("host_port") is int:
				print_debug("invalid CNOK response!")
				return
		
		var conn = ENetConnection.new()
		conn.create_host_bound(addr[0], int(addr[1]))
		conn.connect_to_host(ok.host_ip, ok.host_port)
		res.polling_conn = conn
		
		GameMaster.root_node.add_child(res)
		return res
	
	static func _on_client_requested(json : Dictionary):
		if not _instance or not _instance.is_host:
			print_debug("invalid context for CLRQ!")
			return
		if not json or\
			not json.get("client_ip") is String or\
			not json.get("client_port") is int:
				print_debug("json for CLRQ is ill-formed!")
				return
		var sock = PacketPeerUDP.new()
		sock.bind(0)
		var addr = await NetUtil.request_stun(sock)
		sock.close()
		var conn = ENetConnection.new()
		conn.create_host_bound(addr[0], int(addr[1]))
		conn.socket_send(json.client_ip, json.client_port, "hewwo".to_ascii_buffer())
		_instance.polling_conn = conn
		MMConnection._instance.send("CLOK", {})
	

static var server_connection : MMConnection = null

static var lobby : LobbyInfo = null

static func connect_to_mm_server(port : int, username : String, logger = null):
	if server_connection:
		if logger: logger.call("server connection already exists!")
		return
	#do a stun check
	var sock = PacketPeerUDP.new()
	if sock.bind(port) != OK:
		if logger: logger.call("failed to bind socket to port!")
		return
	else:
		if logger: logger.call("using port " + str(sock.get_local_port()))
	var my_addr = null
	var retry = 0
	while retry < 10:
		my_addr = await NetUtil.request_stun(sock)
		if my_addr: break
		else:
			retry += 1
			if logger: logger.call("STUN fail %d of 10" % [ retry ])
	if not my_addr: return
	if logger: logger.call("STUN success: " + str(my_addr))
	#get the server's ip address
	var res = await NetUtil.mm_request("connreq?port=%d" % [ my_addr[1] ])
	if not res:
		if logger: logger.call("could not reach matchmaking server!")
		return
	if not res.ok:
		if logger: logger.call("server returned error!")
		return
	var conn = MMConnection.new(res.server_ip, res.server_port, sock)
	#at this point, server should alr tried sending a packet to us, so we should be able to send back and connect
	sock.connect_to_host(conn.server_ip, conn.server_port)
	sock.put_packet('HELO'.to_ascii_buffer())
	
	retry = 0
	while true:
		await GameMaster.get_timer(1.0).timeout
		if sock.get_available_packet_count():
			var response = sock.get_packet()
			var srs = response.get_string_from_ascii()
			if srs == "HELA":
				break
			else:
				if logger: logger.call("ignoring unknown packet " + srs)
		retry += 1
		if retry > 10:
			if logger: logger.call("server did not reply!")
			return
	
	var packet = ('ACKH{"username":"%s"}' % [ username ]).to_ascii_buffer()
	sock.put_packet(packet)
	GameMaster.root_node.add_child(conn)
	server_connection = conn
	
	return true

static func create(logger = null):
	if lobby:
		if logger: logger.call("lobby instance already exists!")
		return
	
		lobby = await LobbyInfo.new_host()
	
	pass
	#socket2server.put_packet('SERV{}'.to_ascii_buffer())
	#while not socket2server.get_available_packet_count():
		#await GameMaster.get_timer(2.0).timeout
	#var response = socket2server.get_packet().get_string_from_ascii()
	#if response.begins_with("SROK"):
		#var json = JSON.parse_string(response.substr(4))
		#socket2server.put_packet('SRCK'.to_ascii_buffer())
		#return json.lobby_code

static func join(code):
	pass
