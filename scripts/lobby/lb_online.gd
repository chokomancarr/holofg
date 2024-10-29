extends Node

@onready var lobby_rend : LobbyRend = $"lobby_rend"

var device : InputMan.Device
var state = STATE.SELECT

enum STATE {
	SELECT, UNREADY, READY, STARTING
}

func _ready():
	_ready2.call_deferred()

func _ready2():
	lobby_rend.init()
	
	var lb = OnlineLobby.lobby
	assert(lb, "no online lobby!")
	
	_init_signals(lb, OnlineLobby.signals)
	
	($"lobby_code" as Label).text.replace("XXXX", lb.code)
	
	set_usr(1, lb.p1.nm)
	
	if lb.is_p2:
		lobby_rend.set_input_p_mesh(false, lb.p1.input_ty)
		set_usr(2, lb.p2.nm)
	
	
	if len(InputMan.available_devices) > 1:
		await lobby_rend.setcam(lobby_rend.CPOS_INPUTSEL)
		device = (await lobby_rend.sel_input_p(false)).device
	else:
		var res = await InputMan.get_default_input()
		lobby_rend.set_input_p(false, res)
		device = res.device
	
	await lobby_rend.setcam(lobby_rend.CPOS_CHARASEL)
	
	if lb.is_p2:
		set_chara(false, lb.p1.chara_id, lb.p1.chara_costume)
	
	var cids = await lobby_rend.sel_chara_p(lb.is_p2)
	lb.me().chara_id = cids[0]
	lb.me().chara_costume = lobby_rend.charasel.cids[1]
	lb.broadcast("opp_sel_chara", cids)
	
	state = STATE.UNREADY

func set_usr(i, nm):
	var usr = get_node("mp/usr%d" % i)
	(usr.get_node("icon") as TextureRect).texture = load("res://ui/lobby/user_default.png")
	usr.get_node("noname").visible = false
	usr.get_node("name").visible = true
	usr.get_node("name").text = nm

func unset_usr(i):
	var usr = get_node("mp/usr%d" % i)
	(usr.get_node("icon") as TextureRect).texture = load("res://ui/lobby/user_none.png")
	usr.get_node("noname").visible = true
	usr.get_node("name").visible = false
	get_node("mp/snap/spin%d" % i).visible = false
	lobby_rend.set_chara_p(i == 2, -1)

func set_chara(p2, i, c):
	get_node("mp/snap/spin%d" % (2 if p2 else 1)).visible = (i == -1)
	lobby_rend.set_chara_p(p2, i, c)


func _unhandled_input(e : InputEvent):
	match state:
		STATE.UNREADY:
			if device.if_bt(e, KEY_F, JOY_BUTTON_B):
				OnlineLobby.player_ready(true)
				get_node("mp/snap/rdyprompt").text.replace("Ready", "Unready")
				state = STATE.READY
			elif device.if_bt(e, KEY_ESCAPE, JOY_BUTTON_A):
				var lb = OnlineLobby.lobby
				lobby_rend.set_chara_p(lb.is_p2, -1)
				lb.broadcast("opp_sel_chara", -1)
				state = STATE.SELECT
				var cids = await lobby_rend.sel_chara_p(lb.is_p2)
				lb.me().chara_id = cids[0]
				lb.me().chara_costume = cids[1]
				lb.broadcast("opp_sel_chara", cids)
				get_node("mp/rdyprompt").text.replace("Unready", "Ready")
				state = STATE.UNREADY
		STATE.READY:
			if device.if_bt(e, KEY_F, JOY_BUTTON_B):
				OnlineLobby.player_ready(false)
				get_node("mp/rdyprompt").text.replace("Unready", "Ready")
				state = STATE.UNREADY

func _init_signals(lb, sg):
	if not lb.is_p2:
		sg.on_p2_init_connect.connect(_on_p2_init_connect)
		sg.on_p2_connect_fail.connect(_on_p2_connect_fail)
		sg.on_p2_connected.connect(_on_p2_connected)
	sg.on_broadcast_obj.connect(_on_broadcast_obj)
	sg.on_ppl_ready.connect(_on_ppl_ready)
	sg.on_both_ppl_ready.connect(_on_both_ppl_ready)


func _on_p2_init_connect(nm):
	set_usr(2, nm)
	set_chara(true, -1)
	

func _on_p2_connect_fail():
	unset_usr(2)

func _on_p2_connected():
	pass

func _on_ppl_ready(p2 : bool, b : bool):
	get_node("mp/ready%d" % (2 if p2 else 1)).visible = b

func _on_both_ppl_ready():
	can_unready = false
	if not OnlineLobby.lobby.is_p2:
		lobby_rend.start_vs_screen()
		await lobby_rend.on_vs_screen_end
		OnlineLobby.start_game()

func _on_broadcast(sig : String, o : Variant):
	match msg:
		"opp_sel_input_ty":
			lobby_rend.set_input_p_mesh(!OnlineLobby.lobby.is_p2, o as String)
		"opp_sel_chara":
			set_chara(!OnlineLobby.lobby.is_p2, o[0], o[1])
		_:
			pass