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

func _step_game_state(state_old, p1_inputs, p2_inputs):
	#if state_old.freeze_t < state_old.freeze_n:
	#	var res = ObjUtil.clone(state_old, ST.GameState.new())
	#	res.freeze_t += 1
	#	return res
	#else:
	var state_res1 := PlayerState.from(state_old.p1)
	var state_res2 := PlayerState.from(state_old.p2)
	if state_res1.pos.x > state_res2.pos.x:
		state_res1.pos_is_p2 = true
		state_res2.pos_is_p2 = false
	else:
		state_res1.pos_is_p2 = false
		state_res2.pos_is_p2 = true
	GameMaster.p1_chara_logic.step(state_res1, state_old.p1, p1_inputs)
	GameMaster.p2_chara_logic.step(state_res2, state_old.p2, p2_inputs)
	
	var game_state_res = ObjUtil.clone(state_old, GameState.new())
	#ST.GameState.from_players(state_res1, state_res2)
	game_state_res.p1 = state_res1
	game_state_res.p2 = state_res2
	if game_state_res.is_frozen():
		game_state_res.freeze_t += 1
	else:
		game_state_res.freeze_n = 0
		if state_old.countdown > 0:
			game_state_res.countdown = state_old.countdown - 1
		#GameCollider.step(game_state_res)
	
		#GameMaster.p1_chara_logic.step_post(state_res1, state_old.p1)
		#GameMaster.p2_chara_logic.step_post(state_res2, state_old.p2)

	return game_state_res

func _get_debug_text():
	pass
