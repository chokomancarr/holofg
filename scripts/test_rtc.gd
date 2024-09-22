extends Node

var mp := WebRTCMultiplayerPeer.new()

var is_server = false

var initd = false

@onready var logger = $"Label"
const SPC = "                                                          "
func logg(s, indent = 0):
	logger.text = SPC.substr(0, indent * 3) + s + "\n" + logger.text
	print_debug(s)

func _ready():
	mp.peer_connected.connect(func (i):
		logg("peer %d connected! huzzah!" % i)
		#logg("peer info: " + mp.get_peer(i), 1)
		#print("current peers: ", Array(multiplayer.get_peers()))
	)
	
	mp.peer_disconnected.connect(func (i):
		logg("peer %d disconnected! :(" % i)
	)
	
	$"sendmsg".pressed.connect(func ():
		var msg = $"msg".text
		_on_msg.rpc_id(2 if is_server else 1, msg)
		#_on_msg.rpc(msg)
	)
	
	$"getice".pressed.connect(func ():
		$"TextEdit".text = Marshalls.utf8_to_base64("\n".join(_ice_candidates))
	)

@rpc("any_peer", "call_local")
func _on_msg(s):
	logg("received msg: " + s)

func _create_server():
	is_server = true
	logg("creating server...")
	mp.create_mesh(1)
	
	var peer := WebRTCPeerConnection.new()
	
	assert(!peer.initialize(NetUtil.get_ice_servers()))
	
	logg("paste provided SDP text, and press execute...")
	await $"Button".pressed
	var sdp = Marshalls.base64_to_utf8($"TextEdit".text)
	
	peer.session_description_created.connect(func (type: String, sdp: String):
		logg("session desc created!", 1)
		peer.set_local_description(type, sdp)
		$"type".text = type
		$"TextEdit".text = Marshalls.utf8_to_base64(sdp)
		logg("copy SDP text to other person...")
	)
	
	peer.ice_candidate_created.connect(func (media: String, index: int, name: String):
		#logg("ice candidate created!", 1)
		_ice_candidates.push_back(name)
	)
	
	assert(!mp.add_peer(peer, 2))
	assert(!peer.set_remote_description("offer", sdp))
	multiplayer.multiplayer_peer = mp
	
	await get_tree().create_timer(5.0).timeout
	
	logg("paste provided ICE text, and press execute...")
	await $"Button".pressed
	
	for s in Marshalls.base64_to_utf8($"TextEdit".text).split("\n"):
		peer.add_ice_candidate("0", 0, s)

	($"getice" as Button).pressed.emit()
	logg("copy ICE text to other person...")

var _ice_candidates = []

func _create_client():
	logg("creating client...")
	mp.create_mesh(2)
	
	var peer := WebRTCPeerConnection.new()
	assert(!peer.initialize(NetUtil.get_ice_servers()))
	
	assert(!mp.add_peer(peer, 1))
	
	peer.session_description_created.connect(func (type: String, sdp: String):
		logg("session desc created!", 1)
		peer.set_local_description(type, sdp)
		$"type".text = type
		$"TextEdit".text = Marshalls.utf8_to_base64(sdp)
	)
	
	peer.ice_candidate_created.connect(func (media: String, index: int, name: String):
		logg("ice candidate created!", 1)
		_ice_candidates.push_back(name)
	)
	
	assert(!peer.create_offer())
	multiplayer.multiplayer_peer = mp
	
	logg("waiting for sdp...", 1)
	await $"Button".pressed
	var sdp = Marshalls.base64_to_utf8($"TextEdit".text)
	
	assert(!peer.set_remote_description("answer", sdp))
	
	logg("waiting for ice...", 1)
	await $"Button".pressed
	
	for s in Marshalls.base64_to_utf8($"TextEdit".text).split("\n"):
		peer.add_ice_candidate("0", 0, s)

func _process(delta):
	mp.poll()

func _unhandled_input(event):
	if initd:
		return
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_C:
				_create_client()
				initd = true
			elif event.keycode == KEY_S:
				_create_server()
				initd = true
