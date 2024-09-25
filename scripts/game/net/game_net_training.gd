class_name GameNet_Training extends _GameNetBase

var p1_inputs : InputMan._InputSource
var p2_inputs : InputMan.DummyInput

var dummy_recorder : RecordedInputs
var recording : bool
var playback : bool

var block_ty := ST.BLOCK_TY.NONE
var block_usecd := true
var block_cd := 0

func _ready():
	p1_inputs = InputMan.get_player_input(0)
	p2_inputs = InputMan.DummyInput.new()

func init():
	pass

func start():
	pass

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
		if block_usecd:
			var s2 = GameMaster.game_state.p2
			if s2.state is _CsStunBase:
				if s2.state.check_next(s2) is CsIdle:
					block_cd = 60
			else:
				if block_cd > 0:
					block_cd -= 1
		CsIdle._override_block_ty = block_ty if block_cd == 0 else ST.BLOCK_TY.ALL
		_step_game_state(GameMaster.game_state, p1_inputs.step(), p2_inputs.step())
		if Input.is_key_pressed(KEY_F9):
			_start_recording()
		elif Input.is_key_pressed(KEY_F11):
			_start_playback()
	
	return GameMaster.game_state

func _unhandled_key_input(e: InputEvent):
	if e is InputEventKey and e.is_pressed():
		if e.keycode == KEY_B:
			if not recording and not playback:
				const blks = [ ST.BLOCK_TY.NONE, ST.BLOCK_TY.HIGH, ST.BLOCK_TY.LOW, ST.BLOCK_TY.ALL, ST.BLOCK_TY.NONE ]
				block_ty = blks[blks.find(block_ty) + 1]
		elif e.keycode == KEY_N:
			block_usecd = !block_usecd

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
	var res = ""
	
	res += "%s : switch block [B]\n%s : block after hit [N]\n" % [ ST.BLOCK_TY.find_key(block_ty), "Y" if block_usecd else "N" ]
	
	if recording:
		res += "%d :recording\nF10 to stop" % [ dummy_recorder.n ]
	elif playback:
		res += "%d / %d :playback\nF12 to stop" % [ dummy_recorder.i, dummy_recorder.n ]
	else:
		res += "F9 to record\n" + ((str(dummy_recorder.n) + " recorded\nF11 to playback") if dummy_recorder else "nothing recorded")
	
	return res

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
