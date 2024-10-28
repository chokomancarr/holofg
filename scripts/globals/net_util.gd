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

func _get_stun_addrs():
	var req = HTTPRequest.new()
	get_tree().root.add_child(req)
	req.request_completed.connect(func (res, code, hd, bd : PackedByteArray):
		_stun_addrs = Array(bd.get_string_from_utf8().split("\n"))
		req_complete.emit()
	)
	req.request("https://raw.githubusercontent.com/pradt2/always-online-stun/master/valid_ipv4s.txt")
	await req_complete

func request_stun(socket : PacketPeerUDP, numchecks = 1):
	if not _stun_addrs:
		_get_stun_addrs()
	
	var _do_stun = func ():
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
	
	var res1 = await _do_stun.call()
	if numchecks > 1:
		for c in range(1, numchecks):
			print("doing additional check " + str(c))
			var res2 = await _do_stun.call()
			if res1[0] != res2[0] or res1[1] != res2[1]:
				print("stun fail: result was not same to previous!")
				return null
	return res1

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

func get_ice_servers():
	return {
		"iceServers": _ice_servers
	}


var _ice_servers = [
	{
		"urls": "stun:stun.relay.metered.ca:80",
	},
	{
		"urls": "turn:global.relay.metered.ca:80",
		"username": "4236676feb6f29f42fe275b7",
		"credential": "BQb6gr2s/ZQo+rb0",
	},
	{
		"urls": "turn:global.relay.metered.ca:80?transport=tcp",
		"username": "4236676feb6f29f42fe275b7",
		"credential": "BQb6gr2s/ZQo+rb0",
	},
	{
		"urls": "turn:global.relay.metered.ca:443",
		"username": "4236676feb6f29f42fe275b7",
		"credential": "BQb6gr2s/ZQo+rb0",
	},
	{
		"urls": "turns:global.relay.metered.ca:443?transport=tcp",
		"username": "4236676feb6f29f42fe275b7",
		"credential": "BQb6gr2s/ZQo+rb0",
	},
]
