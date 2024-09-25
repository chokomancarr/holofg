extends Node

static var root_node : Node

func get_timer(t):
	return root_node.get_tree().create_timer(t, true, false, true)

var p1_chara_info : DT.CharaInfo = null
var p2_chara_info : DT.CharaInfo = null
var game_state : GameState = null
var net_master : _GameNetBase = null

var last_updated_time = 0

var all_chara_infos = {}

var anim_lib = {}

var game_speed_scale = 1
var game_paused = false

func _ready():
	#for i in range(1, 3):
	#	all_chara_infos[i] = DT.load_chara(i)
	all_chara_infos[2] = DT.load_chara(2)
	root_node = get_node("/root")

func new_match(p1 : int, p2 : int, ty : _GameNetBase.TY):
	p1_chara_info = all_chara_infos[p1]
	p2_chara_info = all_chara_infos[p2]
	game_state = GameState.from_players(
		PlayerState.create(p1_chara_info, true), 
		PlayerState.create(p2_chara_info, false)
	)
	net_master = _GameNetBase.spawn(ty)
	add_child(net_master)
	net_master.init()
	
	var par = get_node("/root/main/%ppl_spawn")
	
	for c in par.get_children():
		c.queue_free()
	
	var ps1 = load("res://chara_scenes/chara_%d.tscn" % [ p1 ]).instantiate() as CharaRend
	ps1.is_p1 = true
	par.add_child(ps1)
	var ps2 = load("res://chara_scenes/chara_%d.tscn" % [ p2 ]).instantiate() as CharaRend
	ps1.is_p1 = false
	par.add_child(ps2)
	
	ANIM.register(p1, ps1.anim)
	ANIM.register(p2, ps2.anim)
	ANIM.post_register(p1, ps2.anim)
	ANIM.post_register(p2, ps1.anim)
	
	OnlineLobby.game_loaded()

func reset():
	game_state = null
	if net_master:
		net_master.queue_free()

func _process(_dt):
	for i in range(10):
		if Input.is_key_pressed(KEY_0 + i):
			game_speed_scale = 1.0 if not i else 0.1 * i
			Engine.physics_ticks_per_second = roundi(game_speed_scale * 60)

func _physics_process(_dt):
	if net_master:
		game_state = net_master.get_game_state()
		last_updated_time = Time.get_ticks_msec()

func get_state_diff_frame():
	return minf((Time.get_ticks_msec() - last_updated_time) * 0.001 * Engine.physics_ticks_per_second, 1.0)
