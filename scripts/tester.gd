extends Node

@onready var usrnm = "user_" + str(randi_range(1111, 9999))
@onready var logger = $"%dbg" as Label

const SPC = "                                                          "
func logg(s, indent = 1):
	logger.text = SPC.substr(0, indent * 3) + s + "\n" + logger.text
	print_debug(s)

func _ready():
	($"Control/vb/usrnm" as Label).text = usrnm
	($"Control/vb/online" as Button).pressed.connect(_on_connect_mm)
	($"Control/vb/online_bts/srv/Button" as Button).pressed.connect(_on_make_srv)

func _on_connect_mm():
	logg("connecting to mm server...", 0)
	($"Control/vb/online" as Button).disabled = true
	if await OnlineLobby.connect_to_mm_server(0, usrnm, logg):
		$"Control/vb/online".queue_free()
		$"Control/vb/online_bts".visible = true
		logg("success! @ %s:%d" % [
			OnlineLobby.server_connection.server_ip,
			OnlineLobby.server_connection.server_port
		], 0)
	else:
		($"Control/vb/online" as Button).disabled = false
		logg("... failed!", 0)

func _on_make_srv():
	logg("creating lobby...")
	$"Control/vb/online_bts/srv/Button".disabled = true
	var lobby_code = await OnlineLobby.create()
	if lobby_code:
		$"Control/vb/hb/srv/code".text = lobby_code
	$"Control/vb/online_bts/srv/Button".disabled = false

func _on_join_srv():
	logg("joining lobby...")
	$"Control/vb/online_bts/clt/Button".disabled = true
	var lobby_code = $"Control/vb/hb/clt/Button".text
	await OnlineLobby.join(lobby_code)
	$"Control/vb/online_bts/clt/Button".disabled = false
