extends Node

@onready var box_ui : Control = $"/root/main/box_view"
@onready var history_ui : Control = $"/root/main/input_history"
@onready var frame_meter : FrameMeter = $"/root/main/frame_meter"

var ui_cam_off = 0.15
var ui_cam_scl = 2.5

@export var show_hitbox = true

func _ready():
	if not OnlineLobby.lobby:
		_begin.call_deferred()

func _begin():
	GameMaster.new_match(2, 2, _GameNetBase.TY.TRAINING)

func _physics_process(delta):
	var game_state = GameMaster.game_state as GameState
	if not game_state:
		return
	
	_update_input_history_ui(game_state)
	
	if game_state.state == GameState.MATCH_STATE.GAME or game_state.freeze_t == 0:
		frame_meter.step(game_state.p1, game_state.p2)

	if show_hitbox and (game_state.state != GameState.MATCH_STATE.CINEMATIC):
		_draw_debug_chara(game_state.p1, 0)
		_draw_debug_chara(game_state.p2, 1)
	else:
		for bp in _boxview_elems:
			for b in bp:
				b[0].visible = false

@onready var _his_gc = history_ui.get_node("gc")

const _dir_unicode = [
	"-", "↙", "↓", "↘", "←", "", "→", "↖", "↑", "↗"
]

var _last_input = ["?", ""]

func _update_input_history_ui(game_state : GameState):
	#for c in _his_gc.get_children():
	#	c.queue_free()
	var i = game_state.p1.input_history.his[0]
	#var s1 = str(mini(i.nf, 99)) + "  "
	var s2 = _dir_unicode[i.dir()]
	var s3 = ""
	if i.l(): s3 += "L "
	if i.m(): s3 += "M "
	if i.h(): s3 += "H "
	if i.s(): s3 += "S "
	if i.g(): s3 += "✋ "
	if i.p(): s3 += "▲ "
	
	if _last_input[0] == s2 and _last_input[1] == s3:
		_his_gc.get_child(0).text = str(mini(i.nf, 99)) + "  "
	else:
		_last_input[0] = s2
		_last_input[1] = s3
		
		var d = Label.new()
		d.text = str(mini(i.nf, 99)) + "  "
		_his_gc.add_child(d)
		_his_gc.move_child(d, 0)
		d = Label.new()
		d.text = s2
		_his_gc.add_child(d)
		_his_gc.move_child(d, 1)
		d = Label.new()
		d.text = s3
		_his_gc.add_child(d)
		_his_gc.move_child(d, 2)
		
		while _his_gc.get_child_count() > 60:
			_his_gc.get_child(60).free()

var _boxview_elems = [
	[], []
]

func _draw_debug_chara(chara : PlayerState, p):
	var ww = GameMaster.game_state.wall
	var ctr = (ww.x + ww.y) / 2
	
	var boxes = chara.boxes.map(func (b): return [ chara.pos, b.get_rect(chara.action_is_p2), b.ty ])
	for sm in chara.summons:
		boxes.append_array(sm._info.boxes.map(func (b): return [ sm.pos, b.get_rect(sm.is_p2), b.ty ]))
	
	var n = boxes.size()
	var bve = _boxview_elems[p]
	var n2 = bve.size()
	#var sz = get_viewport().size
	var sz = Vector2(1000, 562)
	if n > n2:
		for i in range(n - n2):
			var panel = Panel.new()
			var theme = StyleBoxFlat.new()
			theme.set_border_width_all(2)
			panel.set("theme_override_styles/panel", theme)
			bve.push_back([panel, theme])
			box_ui.add_child(panel)
			n2 = n
	for i in range(n):
		var bb = boxes[i]
		var pos = bb[0]
		var rect = bb[1]
		var pt = bve[i]
		pt[0].visible = true
		pt[0].position = _tr(ST.coord2world(rect.position + pos + Vector2i(5000-ctr, rect.size.y), sz), sz)
		pt[0].size = ST.cmag2world(rect.size, sz) * ui_cam_scl
		pt[1].border_color = ST.get_box_color(bb[2])
		pt[1].bg_color = Color(pt[1].border_color, 0.3)
	
	for i in range(n2 - n):
		bve[n + i][0].visible = false

func _tr(vec, sz):
	vec -= Vector2(sz.x * 0.5, sz.y)
	vec *= ui_cam_scl
	vec += Vector2(sz.x * 0.5, sz.y - ui_cam_off * sz.y)
	return vec

func _unhandled_input(e):
	if not OnlineLobby.lobby:
		if e is InputEventKey and e.is_pressed():
			if e.keycode == KEY_F4:
				GameMaster.new_match(2, 2, _GameNetBase.TY.TRAINING)
