class_name LobbyInputMapper extends Node

signal on_complete

@onready var grid = $"vb/gc"
@onready var acts = $"vb/acts"

var input_map : InputMan.PlayerInput

var show = false:
	set(v):
		self.visible = v
		show = v
		if v:
			_update_names()
var check_i = -1

var bt_lbls : Array[Label] = []

func _ready():
	_ready2.call_deferred()

func _ready2():
	var pnltheme = StyleBoxFlat.new()
	pnltheme.bg_color = Color.WHITE
	
	for nm in InputMan.ActionMap.NMS:
		var lbl = Label.new()
		lbl.text = nm
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(lbl)
		var pnl = Panel.new()
		pnl.add_theme_stylebox_override("panel", pnltheme)
		pnl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pnl.self_modulate = Color(1,1,1,0.1)
		grid.add_child(pnl)
		var lb2 = Label.new()
		lb2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pnl.add_child(lb2)
		bt_lbls.push_back(lb2)

func _update_names():
	for i in range(len(InputMan.ActionMap.NMS)):
		var map = input_map.action_map[InputMan.ActionMap.NMS[i]]
		bt_lbls[i].text = ("gamepad button %d" % map) if input_map.device.is_gamepad else OS.get_keycode_string(map)

func _unhandled_input(e: InputEvent):
	if show:
		if check_i == -1:
			if input_map.device.if_bt(e, KEY_F, JOY_BUTTON_B):
				check_i = 0
				acts.visible = false
				bt_lbls[0].get_parent().self_modulate = Color.ORANGE
			if input_map.device.if_bt(e, KEY_ESCAPE, JOY_BUTTON_A):
				show = false
				InputMan.save_player_input_mapping(input_map)
				on_complete.emit()
				get_viewport().set_input_as_handled()
		else:
			var bt = input_map.device.any_bt(e)
			if bt > -1:
				input_map.action_map[InputMan.ActionMap.NMS[check_i]] = bt
				bt_lbls[check_i].text = ("gamepad button %d" % bt) if input_map.device.is_gamepad else OS.get_keycode_string(bt)
				bt_lbls[check_i].get_parent().self_modulate = Color(1,1,1,0.1)
				check_i += 1
				if check_i == len(InputMan.ActionMap.NMS):
					check_i = -1
					acts.visible = true
				else:
					bt_lbls[check_i].get_parent().self_modulate = Color.ORANGE
