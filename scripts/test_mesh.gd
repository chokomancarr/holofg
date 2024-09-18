extends Node

var net : ENetMultiplayerPeer
var conn : ENetConnection
@onready var lbl = $"Label" as Label

var hosting = false

func _process(delta):
	if conn:
		var res = conn.service()
		var status = res[0]
		if status == ENetConnection.EVENT_CONNECT:
			var peer = res[1] as ENetPacketPeer
			lbl.text += "\npeer connected from port " + str(peer.get_remote_port())
			net.add_mesh_peer(2 if hosting else 1, conn)
			await get_tree().create_timer(1.0).timeout
			if hosting:
				rpc_func.rpc_id(2, "hello from host")
				rpc_func.rpc("hello everyone")
			else:
				rpc_func.rpc("hello from client")

@rpc("any_peer", "call_local")
func rpc_func(s):
	lbl.text += "\nrpc called: " + s

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_S:
			hosting = true
			net = ENetMultiplayerPeer.new()
			net.create_mesh(1)
			multiplayer.multiplayer_peer = net
			conn = ENetConnection.new()
			conn.create_host_bound("*", 5000)
			lbl.text += "\nserving from port " + str(conn.get_local_port())
		elif event.keycode == KEY_C:
			var addr = $"TextEdit".text.split(":")
			net = ENetMultiplayerPeer.new()
			net.create_mesh(2)
			multiplayer.multiplayer_peer = net
			conn = ENetConnection.new()
			conn.create_host_bound("*", 5001)
			lbl.text += "\nconnecting from port " + str(conn.get_local_port())
			conn.connect_to_host("127.0.0.1", 5000)
