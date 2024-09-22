class_name OnlineLobby

signal request_done
signal unhandled_event(obj : Dictionary)

static var signals : OnlineLobby

static var http_client : HTTPClient
static var busy = false
static var poll = false

static var listeners : Dictionary = {}

static func _init_http():
	http_client = HTTPClient.new()
	http_client.blocking_mode_enabled = true
	if http_client.connect_to_host("https://equipped-chamois-big.ngrok-free.app") != OK:
		print_debug("could not connect to host!")
		return false
	
	while true:
		await GameMaster.get_timer(0.1).timeout
		http_client.poll()
		var st = http_client.get_status()
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
	http_client.request(HTTPClient.METHOD_POST, url, headers, JSON.stringify(body))
	
	while not http_client.has_response():
		http_client.poll()
		await GameMaster.get_timer(0.5).timeout
	
	var code = http_client.get_response_code()
	var response = PackedByteArray()
	while true:
		var chunk = http_client.read_response_body_chunk()
		if chunk.is_empty():
			break
		response.append_array(chunk)
	
	var json = JSON.parse_string(response.get_string_from_utf8())
	
	busy = false
	signals.request_done.emit()
	
	return {
		"code": code,
		"body": json if json else {}
	}

static func _poll():
	while busy:
		await signals.request_done
	busy = true
	var headers = PackedStringArray(["ngrok-skip-browser-warning: 69420"])
	http_client.request(HTTPClient.METHOD_GET, "/poll", headers)
	
	while not http_client.has_response():
		http_client.poll()
		await GameMaster.get_timer(0.5).timeout
	
	var code = http_client.get_response_code()
	var response = PackedByteArray()
	while true:
		var chunk = http_client.read_response_body_chunk()
		if chunk.is_empty():
			break
		response.append_array(chunk)
	
	var json = JSON.parse_string(response.get_string_from_utf8())
	
	busy = false
	signals.request_done.emit()
	
	return {
		"code": code,
		"body": json if json else {}
	}


static func init(usrnm : String):
	if signals:
		return
	signals = new()
	
	var res = await _init_http()
	if !res: return false
	
	res = await _post("/hello", "hello", { "username": usrnm })
	if res.code != 200:
		print_debug("hello failed: ", res.code, JSON.stringify(res.body))
		return false
	
	return true

static func create():
	return null

static func join(code):
	return null

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
					signals.unhandled_event.emit(res.body)
			else:
				print_debug("polling returned error: ", res.code, JSON.stringify(res.body))
				poll = false
				return
