class_name Lobby_CharaSel extends Control

signal on_confirm_sel

const p1_col = Color.DODGER_BLUE
const p2_col = Color.MEDIUM_VIOLET_RED

const keymap = {
	ACTION.CONFIRM: [KEY_F, JOY_BUTTON_B],
	ACTION.CANCEL: [KEY_ESCAPE, JOY_BUTTON_A],
	ACTION.LEFT: [KEY_A, JOY_BUTTON_DPAD_LEFT],
	ACTION.RIGHT: [KEY_D, JOY_BUTTON_DPAD_RIGHT],
	ACTION.SETINPUT: [KEY_V, JOY_BUTTON_X],
}

@onready var cc1 = $"cc1"
@onready var cc2 = $"cc2"
@onready var plname = %"palette_name"
@onready var inputmap = $"inputmap" as LobbyInputMapper

var ppl_input : InputMan.PlayerInput
var sel_id = 2

var last_action = ACTION.NONE

func _ready():
	cc1.visible = false
	cc2.visible = false

func sel_chara(pi, p):
	cc1.visible = true
	%"sel_frame".modulate = p1_col if p == 0 else p2_col
	ppl_input = pi
	await wait_for_action(ACTION.CONFIRM)
	cc1.visible = false
	return sel_id

func sel_costume(pinput :InputMan.PlayerInput, cid : int, p2 : bool, plt : CharaPalette):
	cc2.visible = true
	position.x = 600 * int(p2)
	
	var ci = 0
	
	CharaPalette.load_palette(cid)
	var pal = CharaPalette.palette_all[cid].costume1
	
	set_costume(cid, p2, plt, 0)
	
	ppl_input = pinput
	while true:
		last_action = ACTION.NONE
		await on_confirm_sel
		match last_action:
			ACTION.LEFT:
				ci -= 1
				if ci < 0:
					ci = pal.size() - 1
				set_costume(cid, p2, plt, ci)
			ACTION.RIGHT:
				ci += 1
				if ci == pal.size():
					ci = 0
				set_costume(cid, p2, plt, ci)
			ACTION.SETINPUT:
				cc2.visible = false
				inputmap.input_map = ppl_input
				ppl_input = null
				inputmap.show = true
				await inputmap.on_complete
				ppl_input = inputmap.input_map
				cc2.visible = true
			ACTION.CONFIRM:
				cc2.visible = false
				return true
			ACTION.CANCEL:
				cc2.visible = false
				return false

func set_costume(cid : int, p2 : bool, plt : CharaPalette, i : int):
	CharaPalette.load_palette(cid)
	var pal = CharaPalette.palette_all[cid].costume1
	CharaPalette.palette[int(p2)] = pal[i]
	plt.apply_palette(int(p2))
	plname.text = "Color %d" % (i + 1)

func _unhandled_input(e: InputEvent):
	if ppl_input:
		if last_action == ACTION.NONE:
			for k in keymap.keys():
				if ppl_input.device.if_bt(e, keymap[k][0], keymap[k][1]):
					last_action = k
					on_confirm_sel.emit()
					get_viewport().set_input_as_handled()

func wait_for_action(a):
	while true:
		last_action = ACTION.NONE
		await on_confirm_sel
		if last_action == a:
			return

enum ACTION {
	NONE, CONFIRM, CANCEL, LEFT, RIGHT, SETINPUT
}
