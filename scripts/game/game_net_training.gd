class_name GameNet_Training extends _GameNetBase

var p1_inputs : InputMan._InputSource
var p2_inputs : InputMan.DummyInput

var dummy_recorder : RecordedInputs
var recording : bool
var playback : bool

func _ready():
	p1_inputs = InputMan.get_player_input(0)
	p2_inputs = InputMan.DummyInput.new()

func start():
	pass

func get_input_state(is_p1):
	return p1_inputs.step() if is_p1 else p2_inputs.step()

func get_game_state():
	if recording:
		var next = p1_inputs.step()
		dummy_recorder.push(next)
		_step_game_state(GameMaster.game_state, IN.InputState.new(), next)
		if Input.is_key_pressed(KEY_F10):
			_stop_recording()
	elif playback:
		p2_inputs.state = dummy_recorder.next()
		_step_game_state(GameMaster.game_state, p1_inputs.step(), p2_inputs.step())
		if Input.is_key_pressed(KEY_F12):
			_stop_playback()
	else:
		_step_game_state(GameMaster.game_state, p1_inputs.step(), p2_inputs.step())
		if Input.is_key_pressed(KEY_F9):
			_start_recording()
		elif Input.is_key_pressed(KEY_F11):
			_start_playback()
	return GameMaster.game_state


func _start_recording():
	dummy_recorder = RecordedInputs.new()
	recording = true

func _stop_recording():
	recording = false

func _start_playback():
	dummy_recorder.rewind()
	playback = true

func _stop_playback():
	playback = false
	p2_inputs.state = IN.InputState.new()

func _get_debug_text():
	if recording:
		return "%d :recording\nF10 to stop" % [ dummy_recorder.n ]
	elif playback:
		return "%d / %d :playback\nF12 to stop" % [ dummy_recorder.i, dummy_recorder.n ]
	else:
		return "F9 to record\n" + ((str(dummy_recorder.n) + " recorded\nF11 to playback") if dummy_recorder else "nothing recorded")


class RecordedInputs:
	var inputs: Array[IN.InputState]
	var i = -1
	var n = 0
	
	func push(v : IN.InputState):
		inputs.push_back(v)
		n += 1
	
	func rewind():
		i = -1
	
	func next():
		i += 1
		if i == n:
			i = 0
		return inputs[i]
