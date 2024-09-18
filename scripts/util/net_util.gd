extends Node

signal req_complete(int)

var _my_ip : String

var _stun_addrs = null
const _STUN_MAGIC_FLIP = 0x42A41221
const _STUN_MAGIC = 0x2112A442

func _decode_16(arr : PackedByteArray, off : int):
	var res = arr.slice(off, off + 2)
	res.reverse()
	return res.decode_u16(0)

func _get_stun_req_packet():
	var res = PackedByteArray()
	res.resize(8)
	res.encode_u16(0, 0x0100) #binding request 0x0001
	res.encode_u16(2, 0x0000) #message length 0
	res.encode_u32(4, _STUN_MAGIC_FLIP) #magic
	for _i in range(12):
		res.push_back(randi_range(0, 256))
	return res

func request_stun(socket : PacketPeerUDP):
	if not _stun_addrs:
		var req = HTTPRequest.new()
		get_tree().root.add_child(req)
		req.request_completed.connect(func (res, code, hd, bd : PackedByteArray):
			_stun_addrs = Array(bd.get_string_from_utf8().split("\n"))
			req_complete.emit()
		)
		req.request("https://raw.githubusercontent.com/pradt2/always-online-stun/master/valid_ipv4s.txt")
		await req_complete
	
	var _stun_addr = _stun_addrs.pick_random().split(":")
	print("sending stun request to ", _stun_addr)
	socket.connect_to_host(_stun_addr[0], int(_stun_addr[1]))
	socket.put_packet(_get_stun_req_packet())
	while not socket.get_available_packet_count():
		await get_tree().create_timer(0.5).timeout
	var response = socket.get_packet()
	if response.decode_u32(4) != _STUN_MAGIC_FLIP:
		print_debug("stun server returned magic mismatch!")
		return
	## do we really need to do other checks here? ##
	var msglen = _decode_16(response, 2)
	var i = 0
	while i < msglen:
		var aty = _decode_16(response, 20 + i)
		var asz = _decode_16(response, 22 + i)
		if aty == 32:
			var port = _decode_16(response, 26 + i)
			port ^= (_STUN_MAGIC >> 16)
			var ip = "%d.%d.%d.%d" % [
				response[28 + i] ^ ((_STUN_MAGIC & 0xff000000) >> 24),
				response[29 + i] ^ ((_STUN_MAGIC & 0x00ff0000) >> 16),
				response[30 + i] ^ ((_STUN_MAGIC & 0x0000ff00) >> 8),
				response[31 + i] ^ ((_STUN_MAGIC & 0x000000ff) >> 0)
			]
			return [ip, port]
		i += 4 + asz

func get_my_ip():
	var req = HTTPRequest.new()
	get_tree().root.add_child(req)
	req.request_completed.connect(func (res, code, hd, bd):
		_my_ip = bd.get_string_from_utf8()
		req_complete.emit()
	)
	req.request("https://www.icanhazip.com/")
	await req_complete
	
	return _my_ip

var mm_res : Variant

func send_udp(ip : String, port : int, payload : PackedByteArray):
	var sock = PacketPeerUDP.new()
	if sock.connect_to_host(ip, port):
		sock.send(payload, WebSocketPeer.WRITE_MODE_BINARY)

func listen_udp(port : int, callback : Callable):
	var sock = PacketPeerUDP.new()
	if sock.bind(port):
		_listen_udp(sock, callback)
	return sock

func _listen_udp(sock : PacketPeerUDP, callback : Callable):
	while true:
		sock.wait()
		callback.call({
			"ip": sock.get_packet_ip(),
			"port": sock.get_packet_port(),
			"data": sock.get_packet()
		})

func mm_request(params):
	var req = HTTPRequest.new()
	get_tree().root.add_child(req)
	req.request_completed.connect(func (res, code, hd, bd):
		if code == 200:
			mm_res = JSON.parse_string(bd.get_string_from_utf8())
			req_complete.emit(true)
		else:
			req_complete.emit(false)
	)
	var headers = ["ngrok-skip-browser-warning: 69420"]
	req.request("https://equipped-chamois-big.ngrok-free.app/" + params)
	if not await req_complete:
		return null
	return mm_res

#func mm_connect(username, callback = null):
	#var peer = PacketPeerUDP.new()
	#peer.bind(0)
	#
	#print_debug("sending connreq to mm using port ", peer.get_local_port(), "...")
	#
	#var req = HTTPRequest.new()
	#get_tree().root.add_child(req)
	#req.request_completed.connect(func (res, code, hd, bd):
		#var res_s = bd.get_string_from_utf8()
		#mm_res = JSON.parse_string(res_s)
		#req_complete.emit()
	#)
	#var headers = ["ngrok-skip-browser-warning: 69420"]
	#req.request("https://equipped-chamois-big.ngrok-free.app/connreq?user=foo")
	#await req_complete
	#
	#print_debug("mm replied: ", mm_res)
	#if not mm_res or not mm_res["ok"]:
		#return
	#print_debug("connecting to mm...")
	#
	#peer.connect_to_host(mm_res.server_ip, mm_res.server_port)
	#
	#if callback:
		#callback.call(peer)
