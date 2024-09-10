extends Node

var p1_chara_info : DT.CharaInfo = null
var p2_chara_info : DT.CharaInfo = null
var p1_chara_logic : CharaLogic = null
var p2_chara_logic : CharaLogic = null
var game_state : GameState = null
var net_master : _GameNetBase = null

var last_updated_time = 0

var all_chara_infos = {}

var game_speed_scale = 1
var game_paused = false

func _ready():
	all_chara_infos[1] = DT.load_chara(1)

func new_match(p1 : int, p2 : int, ty : _GameNetBase.TY):
	p1_chara_info = all_chara_infos[p1]
	p2_chara_info = all_chara_infos[p2]
	p1_chara_logic = load("res://scripts/chara/chara_logic_%d.gd" % p1).new()
	p2_chara_logic = load("res://scripts/chara/chara_logic_%d.gd" % p2).new()
	game_state = GameState.from_players(
		PlayerState.create(p1_chara_info, true), 
		PlayerState.create(p2_chara_info, false)
	)
	net_master = _GameNetBase.spawn(ty)
	add_child(net_master)

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
