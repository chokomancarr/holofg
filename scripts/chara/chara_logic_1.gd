class_name CharaLogic1 extends CharaLogic

#var force_rename = false
#var res_state : ST.STATE_TY
#func step(state : ST.PlayerState, st_old : ST.PlayerState, inputs : IN.InputState):
	#force_rename = false
	#if state.state == ST.STATE_TY.ACTION:
		#if state.state_t == state.current_action.n_frames - 1:
			#state.state = ST.STATE_TY.IDLE_5
			#force_rename = true
	#if state.stun_t > 0:
		#if state.state_t == state.stun_t - 1:
			#state.stun_t = 0
			#state.state = ST.STATE_TY.IDLE_5
			#force_rename = true
	#_proc_movement(state, inputs)
	#
	##if (state.state & ST.STATE_IDLE_BIT) > 0:
		##tmp
		##if inputs.l == 1:
			##state.action_name = "2l" if (state.state & ST.STATE_CROUCH_BIT) > 0 else "5l"
			##state.state = ST.STATE_TY.ACTION
			##state.current_action = state._info.moves[state.action_name]
		##if inputs.m == 1:
			##state.action_name = "2m" if (state.state & ST.STATE_CROUCH_BIT) > 0 else "5m"
			##state.state = ST.STATE_TY.ACTION
			##state.current_action = state._info.moves[state.action_name]
		##if inputs.h == 1:
			##state.action_name = "2h" if (state.state & ST.STATE_CROUCH_BIT) > 0 else "5h"
			##state.state = ST.STATE_TY.ACTION
			##state.current_action = state._info.moves[state.action_name]
	#
	##if st_old.state == state.state and not force_rename:
		##state.state_t += 1
	##else:
		##state.state_t = 0
		##_update_move_name(state)
	##res_state = state.state
	#
	#_apply_movement(state)
	#_get_boxes(state)
#
#func step_post(state : ST.PlayerState, st_old : ST.PlayerState):
	#if res_state != state.state:
		#state.state_t = 0
		#_update_move_name(state)
		#_get_boxes(state)
	#
	#if state.att_processed and (state.state != ST.STATE_TY.ACTION or state.att_part != ST.ATTACK_PART.ACTIVE):
		#state.att_processed = false
