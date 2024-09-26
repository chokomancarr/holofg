extends Node

class Device:
	var is_gamepad : bool
	var id := 0
	var name : String
	func _init(is_gamepad = false, id = 0, name = "Keyboard"):
		self.is_gamepad = is_gamepad
		self.id = id
		self.name = name

var available_devices : Array[Device]

func _ready():
	available_devices = [ Device.new() ]
	for i in Input.get_connected_joypads():
		available_devices.push_back(Device.new(true, i, Input.get_joy_name(i)))
	Input.joy_connection_changed.connect(_on_pad_change)

func _on_pad_change(i, con):
	if con:
		available_devices.push_back(Device.new(true, i, Input.get_joy_name(i)))
	else:
		for d in available_devices:
			if d.is_gamepad and d.id == i:
				available_devices.erase(d)
				break

class ActionMap:
	var move_up: int
	var move_down: int
	var move_left: int
	var move_right: int
	var button_l: int
	var button_m: int
	var button_h: int
	var button_s: int
	var button_grab: int
	var button_parry: int
	
	const nms = [
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"button_l",
		"button_m",
		"button_h",
		"button_s",
		"button_grab",
		"button_parry"
	]
	
	static func default_kb():
		var res = new()
		const keys = [
			KEY_SPACE, KEY_S, KEY_A, KEY_D,
			KEY_J, KEY_K, KEY_L, KEY_I,
			KEY_U, KEY_O
		]
		for i in len(nms):
			res.set(nms[i], keys[i])
		return res
	static func default_pad():
		var res = new()
		const keys = [
			#JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN,
			#JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT,
			JOY_AXIS_LEFT_Y | JOY_AXIS_BIT, JOY_AXIS_LEFT_Y | JOY_AXIS_BIT,
			JOY_AXIS_LEFT_X | JOY_AXIS_BIT, JOY_AXIS_LEFT_X | JOY_AXIS_BIT,
			JOY_BUTTON_X, JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_Y,
			JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER
		]
		for i in len(nms):
			res.set(nms[i], keys[i])
		return res
	
	func _get_dir(device : Device, va : int, vb : int):
		var _joy = func (v): return Input.is_joy_button_pressed(device.id, v)
		var fn = _joy if device.is_gamepad else Input.is_key_pressed
		if device.is_gamepad && va >= JOY_AXIS_BIT:
			return roundi(Input.get_joy_axis(device.id, va & ~JOY_AXIS_BIT))
		else:
			return (-1 if fn.call(va) else 0) + (1 if fn.call(vb) else 0)
	
	func update(device : Device):
		var _joy = func (v): return Input.is_joy_button_pressed(device.id, v)
		var fn = _joy if device.is_gamepad else Input.is_key_pressed
		var res = IN.InputState.new()
		res.val = 5 + _get_dir(device, move_left, move_right)\
			- 3 * _get_dir(device, move_up, move_down)
		
		var bts = [
			fn.call(button_l),
			fn.call(button_m),
			fn.call(button_h),
			fn.call(button_s),
			fn.call(button_grab),
			fn.call(button_parry)
		]
		
		var i = 8
		for b in bts:
			if b:
				res.val += 1 << i
			i += 4
		
		return res

class _InputSource:
	func step():
		pass

class PlayerInput extends _InputSource:
	var device : Device
	var action_map : ActionMap
	
	func step():
		return action_map.update(device)

class DummyInput extends _InputSource:
	var state = IN.InputState.new()
	
	func step():
		return state

func get_player_input(i):
	var res = PlayerInput.new()
	res.device = available_devices[i]
	res.action_map = ActionMap.default_pad() if res.device.is_gamepad else ActionMap.default_kb()
	
	if not res.device.is_gamepad:
		var folder = "D:/godot/fg"
		if not OS.has_feature("editor"):
			folder = OS.get_executable_path().get_base_dir()
		print_debug(folder)
		var cfgs = FileAccess.open(folder + "/input_cfg.json", FileAccess.READ)
		if cfgs:
			var cfg = JSON.parse_string(cfgs.get_as_text())
			
			if cfg:
				for s in cfg:
					var c = OS.find_keycode_from_string(cfg[s])
					if c > 0:
						res.action_map[s] = c
					else:
						print_debug("unknown remap value ", cfg[s])
	
	return res

const JOY_AXIS_BIT = 1 << 30
