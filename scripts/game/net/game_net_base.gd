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
			return GameNet_Rollback.new()

func init():
	assert(0, "unimplemented!")

func start():
	assert(0, "unimplemented!")

func get_game_state():
	assert(0, "unimplemented!")

func _step_game_state(state : GameState, p1_inputs, p2_inputs):
	var p1 = state.p1.add_inputs(p1_inputs)
	var p2 = state.p2.add_inputs(p2_inputs)
	
	#put this here to avoid 1 frame of freeze with 0 t
	if state.freeze_n > 0 and state.freeze_t == state.freeze_n:
		state.freeze_n = 0
		state.state = GameState.MATCH_STATE.GAME
	
	match state.state:
		GameState.MATCH_STATE.INTRO:
			state.countdown -= 1
			if state.countdown == 0:
				state.state = GameState.MATCH_STATE.PREGAME
				state.countdown = 150
		GameState.MATCH_STATE.PREGAME:
			state.countdown -= 1
			if state.countdown == 0:
				state.state = GameState.MATCH_STATE.GAME
		GameState.MATCH_STATE.GAME:
			if state.countdown > 0:
				state.countdown -= 1
				if state.countdown == 0:
					state.state = GameState.MATCH_STATE.OVER
			
			var flip_p2 = (p1.pos.x > p2.pos.x)
			p1.pos_is_p2 = flip_p2
			p2.pos_is_p2 = !flip_p2
			
			p1.prestep()
			p2.prestep()
			
			var freeze = maxi(p1.state.req_freeze, p2.state.req_freeze)
			if freeze > 0:
				state.freeze(freeze, 1 if p1.state.req_freeze_exclusive else 2 if p2.state.req_freeze_exclusive else 3)
			else:
				p1.step()
				p2.step()
		
				GameCollider.step(state)
				
				if state.p1.bar_health == 0 or state.p2.bar_health == 0:
					state.state = GameState.MATCH_STATE.OVER
			
		GameState.MATCH_STATE.ATT_FREEZE:
			state.freeze_t += 1
		GameState.MATCH_STATE.CINEMATIC:
			state.freeze_t -= 1
			if state.freeze_t == 0:
				state.state = GameState.MATCH_STATE.GAME
		GameState.MATCH_STATE.OVER:
			pass
		GameState.MATCH_STATE.POST_GAME:
			state.countdown -= 1
			if state.countdown == 0:
				state.state = GameState.MATCH_STATE.GAME

func _get_debug_text():
	pass
