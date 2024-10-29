class_name LobbyRend extends Node

signal on_vs_screen_end

@onready var CPOS_INPUTSEL = $"../cpos_inputsel" as Node3D
@onready var CPOS_CHARASEL = $"../cpos_charasel" as Node3D
@onready var CPOS_START = $"../cpos_start" as Node3D
@onready var cam = $"../Camera3D"
@onready var camtar = CPOS_INPUTSEL.transform
@onready var inputsel = $"../inputsel" as Lobby_InputSel
@onready var charasel = $"../charasel" as Lobby_CharaSel

var state = STATE.INPUTSEL

var ppl_inputs : Array[InputMan.PlayerInput] = [null, null]

var cmesh_par : Array[Node]

var start_lerp = -1.0

func init():
	for i in range(2):
		var nd = Node.new()
		nd.name = "chara_mesh_%d" % i
		add_child(nd)
		cmesh_par.push_back(nd)

func sel_input_p(p2 : bool):
	var res = await inputsel.sel_input(int(p2))
	ppl_inputs[int(p2)] = res
	return res

func set_input_p(p2 : bool, ip : InputMan.PlayerInput, showmesh = true):
	ppl_inputs[int(p2)] = ip
	if showmesh:
		inputsel.show_mesh(int(p2), "pad" if ip.device.is_gamepad else "kb")

func set_input_p_mesh(p2 : bool, ty : String):
	inputsel.show_mesh(int(p2), ty)

func sel_chara_p(p2 : bool):
	var cid : int
	var input = ppl_inputs[int(p2)]
	while true:
		cid = await charasel.sel_chara(input, 0)
		
		var nd = set_chara_p(p2, cid)
		
		var cic = await charasel.sel_costume(input, cid, p2, nd.get_node("%palette"))
		if cic > -1:
			return [cid, cic]
		else:
			nd.queue_free()

func set_chara_p(p2 : bool, cid : int, pal = 0):
	var par = cmesh_par[int(p2)]
	if par.has_children():
		par.get_child(0).queue_free()
	if cid < 0:
		return null
	var scn = load("res://chara_scenes/chara_%d_lobby.tscn" % cid) as PackedScene
	var nd = scn.instantiate() as LobbyCharaRend
	nd.p1 = !p2
	
	par.add_child(nd)
	ANIM.register(cid, nd.anim)
	nd.play()
	charasel.set_costume(cid, p2, nd.get_node("%palette"), pal)
	return nd

func setcam(tr):
	camtar = tr.transform
	await get_tree().create_timer(1.0).timeout

func start_vs_screen():
	start_lerp = 0.0

func _process(dt):
	if start_lerp < 0:
		cam.transform = cam.transform.interpolate_with(camtar, 2.0 * dt)
	else:
		start_lerp += dt
		if start_lerp > 1.0:
			on_vs_screen_end.emit()
			SceneMan.load_scene(SceneMan.GAME)
		else:
			cam.transform = camtar.interpolate_with(CPOS_START.transform, pow(start_lerp, 2))


enum STATE {
	INPUTSEL, CHARASEL, INPUTMAP, COSTUMEMAP
}
