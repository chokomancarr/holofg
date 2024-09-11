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
	#var state_res1 := PlayerState.from(state_old.p1)
	#var state_res2 := PlayerState.from(state_old.p2)
	var p1 = state.p1.prestep()
	var p2 = state.p2.prestep()
	var flip_p2 = (p1.pos.x > p2.pos.x)
	p1.pos_is_p2 = flip_p2
	p2.pos_is_p2 = !flip_p2
	
	GameMaster.p1_chara_logic.step(p1, p1_inputs)
	GameMaster.p2_chara_logic.step(p2, p2_inputs)
	
	#var game_state_res = ObjUtil.clone(state_old, GameState.new())
	#ST.GameState.from_players(state_res1, state_res2)
	#game_state_res.p1 = state_res1
	#game_state_res.p2 = state_res2
	if state.is_frozen():
		state.freeze_t += 1
	else:
		state.freeze_n = 0
		if state.countdown > 0:
			state.countdown -= 1
		#GameCollider.step(game_state_res)
	
		#GameMaster.p1_chara_logic.step_post(state_res1, state_old.p1)
		#GameMaster.p2_chara_logic.step_post(state_res2, state_old.p2)

	return state

func _get_debug_text():
	pass
