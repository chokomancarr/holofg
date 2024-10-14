class_name Lobby_CharaSel extends Control

signal on_confirm_sel

const p1_col = Color.DODGER_BLUE
const p2_col = Color.MEDIUM_VIOLET_RED

const keymap = {
	ACTION.CONFIRM: [KEY_F, JOY_BUTTON_B],
	ACTION.CANCEL: [KEY_ESCAPE, JOY_BUTTON_A],
	ACTION.LEFT: [KEY_A, JOY_BUTTON_DPAD_LEFT],
	ACTION.RIGHT: [KEY_D, JOY_BUTTON_DPAD_RIGHT]
}

@onready var cc1 = $"cc1"
@onready var cc2 = $"cc2"
@onready var plname = %"palette_name"

var device = 0
var sel_id = 2

var last_action = ACTION.NONE

func _ready():
	cc1.visible = false
	cc2.visible = false

func sel_chara(dv, p):
	cc1.visible = true
	%"sel_frame".modulate = p1_col if p == 0 else p2_col
	device = dv
	await wait_for_action(ACTION.CONFIRM)
	cc1.visible = false
	return sel_id

func sel_costume(dv, id, p, plt : CharaPalette):
	cc2.visible = true
	position.x = 600 * p
	
	CharaPalette.load_palette(id)
	var pal = CharaPalette.palette_all[id].costume1
	
	var apply = func (i):
		CharaPalette.palette[p] = pal[i]
		plt.apply_palette(p)
		plname.text = "Color %d" % (i + 1)
		
	apply.call(0)
	
	device = dv
	while true:
		last_action = ACTION.NONE
		await on_confirm_sel
		match last_action:
			ACTION.LEFT:
				p -= 1
				if p < 0:
					p = pal.size() - 1
				apply.call(p)
			ACTION.RIGHT:
				p += 1
				if p == pal.size():
					p = 0
				apply.call(p)
			ACTION.CANCEL:
				cc2.visible = false
				return false
			ACTION.CONFIRM:
				cc2.visible = false
				return true

func _unhandled_input(e: InputEvent):
	if last_action == ACTION.NONE:
		if e is InputEventKey:
			if e.device == device:
				if e.pressed:
					for k in keymap.keys():
						if e.keycode == keymap[k][0]:
							last_action = k
							on_confirm_sel.emit()
		elif e is InputEventJoypadButton:
			if e.device == device - 100:
				if e.pressed:
					for k in keymap.keys():
						if e.button_index == keymap[k][1]:
							last_action = k
							on_confirm_sel.emit()

func wait_for_action(a):
	while true:
		last_action = ACTION.NONE
		await on_confirm_sel
		if last_action == a:
			return

enum ACTION {
	NONE, CONFIRM, CANCEL, LEFT, RIGHT
}
