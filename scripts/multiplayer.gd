extends Node

var active = false
var is_server = false
var my_id = 1

func init():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(5000, 1)
	if err == Error.OK:
		is_server = true
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(on_client_connect)
		DisplayServer.window_set_title("FG (p1)")
	else:
		err = peer.create_client("127.0.0.1", 5000)
		if err == Error.OK:
			#print_debug("client created")
			multiplayer.multiplayer_peer = peer
			multiplayer.connected_to_server.connect(on_server_connect)
			DisplayServer.window_set_title("FG (p2)")
	
	DisplayServer.window_set_position(Vector2(10 if is_server else 900, 200))
	active = true

func on_server_connect():
	SyncManager.add_peer(1)

func on_client_connect(c):
	SyncManager.add_peer(c)
	my_client_id.rpc_id(c, c)
	set_input_ids(1, c)

@rpc("authority")
func my_client_id(c):
	my_id = c
	set_input_ids(1, c)
	client_ready.rpc_id(1)

@rpc("any_peer")
func client_ready():
	SyncManager.start()

func set_input_ids(a, b):
	var p1 = get_node("/root/main/p1_sync")
	p1.client_id = a
	p1.init()
	var p2 = get_node("/root/main/p2_sync")
	p2.client_id = b
	p2.init()
