class_name _GameNetBase extends Node

enum TY {
	OFFLINE,
	ONLINE
}

static func spawn(ty):
	match ty:
		TY.OFFLINE:
			return GameNet_Offline.new()
		TY.ONLINE:
			pass

func start():
	pass

func get_input_state(is_p1):
	pass

func get_game_state():
	pass

func _step_game_state(state : GameState, p1_inputs, p2_inputs):
	state.p1.add_inputs(p1_inputs)
	state.p2.add_inputs(p2_inputs)
	
	if state.is_frozen():
		state.freeze_t += 1
		return
	else:
		state.freeze_n = 0
		if state.countdown > 0:
			state.countdown -= 1
			if state.countdown == 0:
				return
	
	var p1 = state.p1.prestep()
	var p2 = state.p2.prestep()
	
	var flip_p2 = (p1.pos.x > p2.pos.x)
	p1.pos_is_p2 = flip_p2
	p2.pos_is_p2 = !flip_p2
	
	p1.step()
	p2.step()
	
	#GameMaster.p1_chara_logic.step(p1, p1_inputs)
	#GameMaster.p2_chara_logic.step(p2, p2_inputs)
	
	GameCollider.step(state)

	#GameMaster.p1_chara_logic.step_post(state_res1, state_old.p1)
	#GameMaster.p2_chara_logic.step_post(state_res2, state_old.p2)

func _get_debug_text():
	pass
