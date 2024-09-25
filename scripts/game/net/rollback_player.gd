class_name RbPlayer extends Node

var client_id: int
var input_source : InputMan._InputSource
var current_input : IN.InputState

func init(id, src):
	name = "_rbplayer_" + str(id)
	client_id = id
	input_source = src
	set_multiplayer_authority(client_id)
	add_to_group("network_sync")

func _get_local_input() -> Dictionary:
	return input_source.step().serialize4input()

#func _predict_remote_input(prev : Dictionary, ntick : int) -> Dictionary:
#	if ntick < 0:
#		return IN.InputState.new().serialize()
#	else:
#		return prev

func _network_preprocess(d : Dictionary):
	current_input = IN.InputState.deserialize4input(d)
