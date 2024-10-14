extends Node

@onready var cpos_inputsel = $"../cpos_inputsel" as Node3D
@onready var cpos_charasel = $"../cpos_charasel" as Node3D
@onready var cpos_start = $"../cpos_start" as Node3D
@onready var cam = $"../Camera3D"
@onready var camtar = cpos_inputsel.transform
@onready var inputsel = $"../inputsel" as Lobby_InputSel
@onready var charasel = $"../charasel" as Lobby_CharaSel

var state = STATE.INPUTSEL
var cmesh_par : Array[Node]

var start_lerp = -1.0

func load_chara(dv, i, p1):
	if i < 0:
		return
	var scn = load("res://chara_scenes/chara_%d_lobby.tscn" % i) as PackedScene
	var nd = scn.instantiate() as LobbyCharaRend
	nd.p1 = p1
	
	var p = 0 if p1 else 1
	
	cmesh_par[p].add_child(nd)
	
	ANIM.register(i, nd.anim)
	nd.play()
	
	var res = await charasel.sel_costume(dv, i, p, nd.get_node("%palette"))
	
	if not res:
		nd.queue_free()
	
	return res

func _ready():
	load_start.call_deferred(true, true)

func load_start(sel_p1, sel_p2):
	for i in range(2):
		var nd = Node.new()
		nd.name = "chara_mesh_%d" % i
		add_child(nd)
		cmesh_par.push_back(nd)

	await GameMaster.get_timer(1.5).timeout
	var device1 = {}
	var device2 = {}
	if sel_p1:
		device1 = await inputsel.sel_input(0)
	else:
		inputsel.show_mesh(0, OnlineLobby.lobby.p1.input_ty)
	if sel_p2:
		device2 = await inputsel.sel_input(1)
	else:
		pass
	camtar = cpos_charasel.transform
	await GameMaster.get_timer(1.5).timeout
	
	var chara1 = -1
	var chara2 = -1
	
	while true:
		if sel_p1:
			chara1 = await charasel.sel_chara(device1.id, 0)
		else:
			chara1 = 2
		if await load_chara(device1.id, chara1, true):
			break
	
	while true:
		if sel_p2:
			chara2 = await charasel.sel_chara(device2.id, 1)
		else:
			chara2 = 2
		if await load_chara(device2.id, chara2, false):
			break
	
	await GameMaster.get_timer(1.0).timeout
	start_lerp = 0.0

func _process(dt):
	if start_lerp < 0:
		cam.transform = cam.transform.interpolate_with(camtar, 2.0 * dt)
	else:
		start_lerp += dt
		if start_lerp > 1.0:
			SceneMan.load_scene(SceneMan.GAME)
		else:
			cam.transform = camtar.interpolate_with(cpos_start.transform, pow(start_lerp, 2))


enum STATE {
	INPUTSEL, CHARASEL, INPUTMAP, COSTUMEMAP
}
