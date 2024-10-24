class_name GameNet_Offline extends _GameNetBase

var p1_inputs : InputMan._InputSource
var p2_inputs : InputMan._InputSource

func _ready():
	p1_inputs = InputMan.get_player_input(0)
	p2_inputs = InputMan.get_player_input(1)

func start():
	pass

func get_game_state():
	_step_game_state(GameMaster.game_state, p1_inputs.step(), p2_inputs.step())
	return GameMaster.game_state

func _get_debug_text():
	var p1 = p1_inputs as InputMan.PlayerInput
	var p2 = p2_inputs as InputMan.PlayerInput
	return "%s P1\n%s P2" % [ p1.device.name if p1 else "no input source", p2.device.name if p2 else "no input source" ]
