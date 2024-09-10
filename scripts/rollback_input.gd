extends Node

@export var client_id: int

var current_input : IN.InputState = IN.InputState.new()

func init():
	set_multiplayer_authority(client_id)

func _get_local_input():
	if DisplayServer.window_is_focused():
		return IN.InputState.from_player().serialize()
	else:
		return IN.InputState.new().serialize()

func _network_preprocess(d):
	current_input = IN.InputState.deserialize(d)

func _physics_process(delta):
	if not MultiMaster.active and (client_id == 1):
		current_input = IN.InputState.from_player()
