class_name _GameNetBase extends Node

enum TY {
	OFFLINE,
	ONLINE,
	TRAINING,
}

static func spawn(ty):
	match ty:
		TY.OFFLINE:
			return GameNet_Offline.new()
		TY.TRAINING:
			return GameNet_Training.new()
		TY.ONLINE:
			pass

func start():
	pass

func get_input_state(is_p1):
	pass

func get_game_state():
	pass

func _step_game_state(state : GameState, p1_inputs, p2_inputs):
	var p1 = state.p1.add_inputs(p1_inputs)
	var p2 = state.p2.add_inputs(p2_inputs)
	
	if state.is_frozen():
		if state.freeze_t == state.freeze_n:
			state.freeze_n = 0
		else:
			state.freeze_t += 1
			return

	if state.countdown > 0:
		state.countdown -= 1
		if state.countdown == 0:
			return
	
	p1.prestep()
	p2.prestep()
	
	var flip_p2 = (p1.pos.x > p2.pos.x)
	p1.pos_is_p2 = flip_p2
	p2.pos_is_p2 = !flip_p2
	
	p1.step()
	p2.step()
	
	var freeze = maxi(p1.state.req_freeze, p2.state.req_freeze)
	if freeze > 0:
		state.freeze(freeze)
	
	GameCollider.step(state)

func _get_debug_text():
	pass
