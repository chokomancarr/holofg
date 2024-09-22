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
	if await OnlineLobby.init(usrnm):
		$"Control/vb/online".queue_free()
		$"Control/vb/online_bts".visible = true
		logg("connected to server!")
	else:
		($"Control/vb/online" as Button).disabled = false
		logg("... failed!", 0)

func _on_make_srv():
	logg("creating lobby...")
	$"Control/vb/online_bts/srv/Button".disabled = true
	var lobby_code = await OnlineLobby.create(logg)
	if lobby_code:
		$"Control/vb/online_bts".visible = false
		$"Control/vb/lobby".visible = true
		($"Control/vb/lobby/p1" as Label).text = usrnm
		($"Control/vb/lobby/lobbycode" as Label).text = lobby_code
		#OnlineLobby.LobbyInfo._instance.client_connected.connect(_on_p2)
		logg("...success!")
	else:
		logg("...failed!")
		$"Control/vb/online_bts/srv/Button".disabled = false


func _on_p2():
	pass

func _on_join_srv():
	logg("joining lobby...")
	$"Control/vb/online_bts/clt/Button".disabled = true
	var lobby_code = $"Control/vb/hb/clt/Button".text
	var ok = await OnlineLobby.join(lobby_code, logg)
	if ok:
		pass
	else:
		logg("...failed!")
		$"Control/vb/online_bts/clt/Button".disabled = false
