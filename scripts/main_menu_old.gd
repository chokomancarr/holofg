extends Node

@onready var usrnm = "user_" + str(randi_range(1111, 9999))
@onready var logger = $"%dbg" as Label

const SPC = "                                                      "
func logg(s, indent = 1):
	logger.text = SPC.substr(0, indent * 3) + s + "\n" + logger.text
	print_debug(s)

func _ready():
	($"Control/vb/usrnm" as Label).text = usrnm
	($"Control/vb/online" as Button).pressed.connect(_on_connect_mm)
	($"Control/vb/online_bts/srv/Button" as Button).pressed.connect(_on_make_srv)
	($"Control/vb/online_bts/clt/Button" as Button).pressed.connect(_on_join_srv)
	($"Control/vb/lobby/Button" as Button).pressed.connect(_on_ready)
	($"Control/vb/chat/CButton" as Button).pressed.connect(_on_send_chat)
	($"Control/vb/train" as Button).pressed.connect(_on_training_mode)
	
	OnlineLobby.lobby = null
	GameMaster.reset_net_master()
	
func _on_training_mode():
	SceneMan.load_scene(SceneMan.LOBBY)

func _on_connect_mm():
	logg("connecting to mm server...", 0)
	($"Control/vb/online" as Button).disabled = true
	if await OnlineLobby.init(usrnm):
		$"Control/vb/online".queue_free()
		$"Control/vb/online_bts".visible = true
		logg("connected to server!")
		
		OnlineLobby.signals.on_ppl_rdy.connect(func (id, r):
			logg("player %d is %sready" % [id, "" if r else "not "])
		)
		OnlineLobby.signals.on_chat_msg.connect(func (msg):
			logg("received message: " + msg)
		)
		OnlineLobby.signals.on_broadcast.connect(func (msg):
			logg(msg)
		)
		OnlineLobby.start_polling_loop()
		pass
	else:
		($"Control/vb/online" as Button).disabled = false
		logg("... failed!", 0)

func _on_make_srv():
	logg("creating lobby...")
	$"Control/vb/online_bts/srv/Button".disabled = true
	var lobby = await OnlineLobby.create()
	if lobby:
		$"Control/vb/online_bts".visible = false
		$"Control/vb/lobby".visible = true
		($"Control/vb/lobby/p1" as Label).text = usrnm
		($"Control/vb/lobby/lobbycode" as Label).text = lobby.code
		lobby.on_p2.connect(_on_p2)
		logg("...success!")
	else:
		logg("...failed!")
		$"Control/vb/online_bts/srv/Button".disabled = false


func _on_p2(p2):
	logg("p2 connected!")
	($"Control/vb/lobby/p2" as Label).text = p2.nm
	($"Control/vb/lobby/Button" as Button).disabled = false
	$"Control/vb/chat".visible = true

func _on_join_srv():
	logg("joining lobby...")
	$"Control/vb/online_bts/clt/Button".disabled = true
	var lobby_code = $"Control/vb/online_bts/clt/code".text
	var lobby = await OnlineLobby.join(lobby_code)
	if lobby:
		$"Control/vb/online_bts".visible = false
		$"Control/vb/lobby".visible = true
		($"Control/vb/lobby/p1" as Label).text = lobby.p1.nm
		($"Control/vb/lobby/p2" as Label).text = usrnm
		($"Control/vb/lobby/lobbycode" as Label).text = lobby.code
		($"Control/vb/lobby/Button" as Button).disabled = false
		$"Control/vb/chat".visible = true
		logg("...success!")
	else:
		logg("...failed!")
		$"Control/vb/online_bts/clt/Button".disabled = false

var rdy = false
func _on_ready():
	rdy = !rdy
	$"Control/vb/lobby/Button".text = "Un-ready" if rdy else "Ready"
	OnlineLobby.player_ready(rdy)

func _on_send_chat():
	var msg = $"Control/vb/chat/TextEdit".text
	$"Control/vb/chat/TextEdit".text = ""
	logg("sent message: " + msg)
	OnlineLobby.send_chat(msg)
