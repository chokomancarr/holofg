extends Node

var available_devices : Array[Device]
var default_device : Device

var waiting_for_device = false
signal on_waited_device
var _waited_device : Device

class Device:
	var is_gamepad : bool
	var id := 0
	var name : String
	
	func _init(is_gamepad = false, id = 0, name = "Keyboard"):
		self.is_gamepad = is_gamepad
		self.id = id
		self.name = name
	
	func any_bt(e : InputEvent):
		if is_gamepad:
			if e is InputEventJoypadButton:
				if e.device == id:
					if e.pressed:
						return e.button_index
		else:
			if e is InputEventKey:
				if e.device == id:
					if e.pressed:
						return e.keycode
		return -1
	
	func if_bt(e : InputEvent, kb : Key, pd : JoyButton):
		if is_gamepad:
			if e is InputEventJoypadButton:
				if e.device == id:
					if e.pressed:
						return e.button_index == pd
		else:
			if e is InputEventKey:
				if e.device == id:
					if e.pressed and not e.echo:
						return e.keycode == kb
		return false

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
	
	const NMS = [
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
		for i in len(NMS):
			res.set(NMS[i], keys[i])
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
		for i in len(NMS):
			res.set(NMS[i], keys[i])
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

func wait_for_any_device():
	waiting_for_device = true
	await on_waited_device
	waiting_for_device = false
	return _waited_device

func get_default_input():
	if not default_device:
		default_device = await wait_for_any_device()
	var res = PlayerInput.new()
	res.device = default_device
	res.action_map = load_player_input_mapping(res.device.is_gamepad)
	return res

func get_player_input(i):
	var res = PlayerInput.new()
	res.device = available_devices[i]
	res.action_map = load_player_input_mapping(res.device.is_gamepad)
	return res

func save_player_input_mapping(pi : PlayerInput):
	var folder = "D:/godot/fg" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir()
	var cfgs = FileAccess.open(folder + "/input_cfg_%s.json" % ("pad" if pi.device.is_gamepad else "kb"), FileAccess.WRITE)
	if cfgs:
		var res = {}
		for nm in ActionMap.NMS:
			res[nm] = pi.action_map[nm]
		cfgs.store_string(JSON.stringify(res, "   ", false))

func load_player_input_mapping(pad : bool):
	var map = ActionMap.default_pad() if pad else ActionMap.default_kb()
	var folder = "D:/godot/fg" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir()
	var cfgs = FileAccess.open(folder + "/input_cfg_%s.json" % ("pad" if pad else "kb"), FileAccess.READ)
	if cfgs:
		var cfg = JSON.parse_string(cfgs.get_as_text())
		if cfg:
			for s in cfg:
				map[s] = cfg[s]
	return map

const JOY_AXIS_BIT = 1 << 30


func _unhandled_input(e: InputEvent):
	if waiting_for_device:
		if e is InputEventKey:
			if e.pressed:
				_waited_device = Device.new()
				on_waited_device.emit()
		elif e is InputEventJoypadButton:
			if e.pressed:
				_waited_device = Device.new(true, e.device, Input.get_joy_name(e.device))
				on_waited_device.emit()
