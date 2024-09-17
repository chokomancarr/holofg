class_name OnlineLobby

static func connect_to_mm_server(port = 8000, logger = null):
	#do a stun check
	var sock = PacketPeerUDP.new()
	sock.bind(port)
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
	if not res or not res.ok: return
	var server_ip = res.ip
	var server_port = res.port
	#at this point, server should alr tried sending a packet to us, so we should be able to send back and connect
	sock.connect_to_host(server_ip, server_port)
	sock.put_packet('HELO'.to_ascii_buffer())
	while not sock.get_available_packet_count():
		await GameMaster.get_timer(2.0).timeout
	var response = sock.get_packet()
	print_debug(response)

static func create(name, cb_ok : Callable, cb_fail = null):
	var res = await NetUtil.mm_request("ty=host&name=%s" % [ name ])
	if res and res.ok:
		cb_ok.call(res.lobby_id)
	elif cb_fail:
		cb_fail.call()

static func join(name, lobby_id, cb_ok : Callable, cb_fail = null):
	var res = await NetUtil.mm_request("ty=join&name=%s&lobby=%s" % [ name, lobby_id ])
	if res and res.ok:
		var aa = res.hostaddr.split(":")
		NetUtil.send_udp(aa[0], aa[1], "ping".to_utf8_buffer())
	elif cb_fail:
		cb_fail.call()



