class_name OnlineLobby

#static func init():

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



