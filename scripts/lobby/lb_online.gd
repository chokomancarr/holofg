extends Node

@onready var lobby_rend : LobbyRend = $"lobby_rend"

func _ready():
	_ready2.call_deferred()

func _ready2():
	lobby_rend.init()
	
	var lb = OnlineLobby.lobby
	assert(lb, "no online lobby!")
	
	($"lobby_code" as Label).text.replace("XXXX", lb.code)
	
	set_usr(1, lb.p1.nm)
	
	if lb.is_p2:
		lobby_rend.set_input_p_mesh(false, lb.p1.input_ty)
		set_usr(2, lb.p2.nm)
	
	
	if len(InputMan.available_devices) > 1:
		await lobby_rend.setcam(lobby_rend.CPOS_INPUTSEL)
		await lobby_rend.sel_input_p(false)
	else:
		lobby_rend.set_input_p(false, await InputMan.get_default_input())
	
	await lobby_rend.setcam(lobby_rend.CPOS_CHARASEL)
	
	if lb.is_p2:
		lobby_rend.set_chara_p(false, lb.p1.chara_id)
	
	await lobby_rend.sel_chara_p(lb.is_p2)
	
	await get_tree().create_timer(1.0).timeout
	lobby_rend.start_vs_screen()

func set_usr(i, nm):
	var usr = get_node("mp/usr%d" % i)
	(usr.get_node("icon") as TextureRect).texture = load("res://ui/lobby/user_default.png")
	usr.get_node("noname").visible = false
	usr.get_node("name").visible = true
	usr.get_node("name").text = nm
