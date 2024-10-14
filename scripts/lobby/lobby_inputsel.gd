class_name Lobby_InputSel extends Control

signal on_any_key
signal on_confirm_src

var ctrl_meshes = [{}, {}]

@onready var cc1 = $"cc1"
@onready var cc2 = $"cc2"
@onready var cc2_name = cc2.get_node("vb/device_name") as Label
@onready var cc2_confirm = cc2.get_node("vb/confirm") as Label
@onready var cc2_cancel = cc2.get_node("vb/cancel") as Label

var last_device = 0
var last_device_ty = 0
var confirm_src = -10

func _ready():
	for s in [ "kb", "pad" ]:
		ctrl_meshes[0][s] = get_node("../charaselect/ctrl_%s_p1" % s)
		ctrl_meshes[1][s] = get_node("../charaselect/ctrl_%s_p2" % s)
	visible = false

func sel_input(p):
	visible = true
	
	position.x = 400 * p
	
	while true:
		for m in ctrl_meshes[p].keys():
			ctrl_meshes[p][m].visible = false
		
		cc1.visible = true
		cc2.visible = false
		
		last_device = -1
		await on_any_key
		
		cc1.visible = false
		cc2.visible = true
		show_mesh(p, last_device_ty)
		
		confirm_src = 0
		await on_confirm_src
		
		if confirm_src == 1:
			visible = false
			return {
				"id": last_device,
				"ty": last_device_ty,
				"name": cc2_name.text
			}

func show_mesh(p, ty):
	ctrl_meshes[p][ty].visible = true

func _process(dt):
	pass

func _unhandled_input(e: InputEvent):
	if last_device < 0:
		if e is InputEventKey:
			if e.pressed:
				last_device = e.device
				last_device_ty = "kb"
				cc2_name.text = "Keyboard"
				on_any_key.emit()
		elif e is InputEventJoypadButton:
			if e.pressed:
				last_device = e.device + 100
				last_device_ty = "pad"
				cc2_name.text = Input.get_joy_name(e.device)
				on_any_key.emit()
	elif confirm_src == 0:
		if e is InputEventKey:
			if e.device == last_device:
				if e.pressed:
					if e.keycode == KEY_F:
						confirm_src = 1
						on_confirm_src.emit()
					if e.keycode == KEY_ESCAPE:
						confirm_src = -1
						on_confirm_src.emit()
		elif e is InputEventJoypadButton:
			if e.device == last_device - 100:
				if e.pressed:
					if e.button_index == JOY_BUTTON_B:
						confirm_src = 1
						on_confirm_src.emit()
					if e.button_index == JOY_BUTTON_A:
						confirm_src = -1
						on_confirm_src.emit()
