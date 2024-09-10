extends Node

@onready var control : Control = $"Control"
@onready var sprite_p1 : AnimatedSprite2D = $"sprite_p1"
@onready var sprite_p2 : AnimatedSprite2D = $"sprite_p2"
@onready var debug_ui : Control = $"/root/main/debug"
@onready var history_ui : Control = $"/root/main/input_history"
@onready var frame_meter : FrameMeter = $"/root/main/frame_meter"

var ui_cam_off = 0.2
var ui_cam_scl = 2.0

func _ready():
	GameMaster.new_match(1, 1, _GameNetBase.TY.OFFLINE)
	
	sprite_p1.speed_scale = Engine.physics_ticks_per_second / 60.0

func _physics_process(delta):
	for c in control.get_children():
		c.queue_free()
	
	var sz = get_viewport().size
	
	var game_state = GameMaster.game_state
	
	if game_state.freeze_n == 0 || game_state.freeze_t == 0:
		sprite_p1.play()
		sprite_p2.play()
	else:
		sprite_p1.pause()
		sprite_p2.pause()
	
	_draw_chara_sprite(game_state.p1, sz, sprite_p1, delta)
	_draw_chara_sprite(game_state.p2, sz, sprite_p2, delta)

	_draw_debug_chara(game_state.p1, sz)
	_draw_debug_chara(game_state.p2, sz)
	
	_update_debug_ui(game_state, GameMaster.net_master.get_input_state(true))
	
	_update_input_history_ui(game_state)
	
	if game_state.freeze_n == 0 || game_state.freeze_t == 0:
		frame_meter.step(game_state.p1, game_state.p2)

func _draw_chara_sprite(chara : ST.PlayerState, sz, sprite : AnimatedSprite2D, delta):
	if sprite.animation == chara.move_name:
		pass
		#sprite.frame += 1
	else:
		sprite.play(chara.move_name)
		#sprite.animation = chara.move_name
	sprite.position = ST.coord2world(chara.pos, sz)

func _draw_debug_chara(chara, sz):
	for b : ST.BoxInfo in chara.boxes:
		var panel = Panel.new()
		var theme = StyleBoxFlat.new()
		theme.set_border_width_all(2)
		theme.border_color = ST.get_box_color(b.ty)
		theme.bg_color = Color(theme.border_color, 0.5)
		panel.set("theme_override_styles/panel", theme)
		panel.position = ST.coord2world(b.rect.position + chara.pos + Vector2i(0, b.rect.size.y), sz) * ui_cam_scl + Vector2(0, ui_cam_off * sz.y)
		panel.size = ST.cmag2world(b.rect.size, sz) * ui_cam_scl
		control.add_child(panel)

func _update_debug_ui(game_state, inputs : IN.InputState):
	(debug_ui.get_node("gc/dir") as Label).text = str(inputs.dir())
	(debug_ui.get_node("gc/att_l") as Label).text = str(inputs.l())
	(debug_ui.get_node("gc/att_m") as Label).text = str(inputs.m())
	(debug_ui.get_node("gc/att_h") as Label).text = str(inputs.h())
	(debug_ui.get_node("gc/att_s") as Label).text = str(inputs.s())

@onready var _his_gc = history_ui.get_node("gc")

func _update_input_history_ui(game_state : ST.GameState):
	for c in _his_gc.get_children():
		c.queue_free()
	
	var arr = game_state.p1.input_history.slice(-1, 0, -1)
	
	for i in arr:
		var d = Label.new()
		d.text = str(mini(i.nf, 99)) + "  "
		_his_gc.add_child(d)
		d = Label.new()
		d.text = str(i.dir())
		_his_gc.add_child(d)
		d = Label.new()
		if i.l(): d.text += "L "
		if i.m(): d.text += "M "
		if i.h(): d.text += "H "
		if i.s(): d.text += "S "
		_his_gc.add_child(d)
