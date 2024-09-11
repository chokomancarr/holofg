extends Node

@onready var box_ui : Control = $"/root/main/box_view"
@onready var history_ui : Control = $"/root/main/input_history"
@onready var frame_meter : FrameMeter = $"/root/main/frame_meter"

var ui_cam_off = 0.15
var ui_cam_scl = 2.0

@export var show_hitbox = true

func _ready():
	_begin.call_deferred()

func _begin():
	GameMaster.new_match(1, 1, _GameNetBase.TY.OFFLINE)
	#print_debug(await NetUtil.get_my_ip())

func _physics_process(delta):
	var game_state = GameMaster.game_state
	if not game_state:
		return
	
	_update_input_history_ui(game_state)
	
	#if game_state.freeze_n == 0 || game_state.freeze_t == 0:
		#frame_meter.step(game_state.p1, game_state.p2)

	if show_hitbox:
		_draw_debug_chara(game_state.p1, 0)
		_draw_debug_chara(game_state.p2, 1)

@onready var _his_gc = history_ui.get_node("gc")

const _dir_unicode = [
	"-", "↙", "↓", "↘", "←", "", "→", "↖", "↑", "↗"
]

func _update_input_history_ui(game_state : GameState):
	pass
#	for c in _his_gc.get_children():
#		c.queue_free()
#	
#	for i in game_state.p1.input_history.history:
#		var d = Label.new()
#		d.text = str(mini(i.nf, 99)) + "  "
#		_his_gc.add_child(d)
#		d = Label.new()
#		d.text = _dir_unicode[i.dir()]
#		_his_gc.add_child(d)
#		d = Label.new()
#		if i.l(): d.text += "L "
#		if i.m(): d.text += "M "
#		if i.h(): d.text += "H "
#		if i.s(): d.text += "S "
#		_his_gc.add_child(d)

var _boxview_elems = [
	[], []
]

func _draw_debug_chara(chara : PlayerState, p):
	var ww = GameMaster.game_state.wall
	var ctr = (ww.x + ww.y) / 2
	
	var n = chara.boxes.size()
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
		var b = chara.boxes[i]
		var pt = bve[i]
		pt[0].visible = true
		pt[0].position = _tr(ST.coord2world(b.rect.position + chara.pos + Vector2i(5000-ctr, b.rect.size.y), sz), sz)
		pt[0].size = ST.cmag2world(b.rect.size, sz) * ui_cam_scl
		pt[1].border_color = ST.get_box_color(b.ty)
		pt[1].bg_color = Color(pt[1].border_color, 0.3)
	for i in range(n2 - n):
		bve[n + i][0].visible = false

func _tr(vec, sz):
	vec -= Vector2(sz.x * 0.5, sz.y)
	vec *= ui_cam_scl
	vec += Vector2(sz.x * 0.5, sz.y - ui_cam_off * sz.y)
	return vec
