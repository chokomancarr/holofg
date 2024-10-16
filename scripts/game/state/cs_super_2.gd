class_name CsSuper2 extends _CsAttBase

const _STATE_NAME = "super_2"

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[], []
	)

static func try_next(state : PlayerState, sliceback : int):
	if state.bar_super >= 2000:
		return _check_inputs(state, sliceback, func (st, n, dd):
			var move = state._info.moves_su_2
			if move:
				if move.cmd.check(st, dd):
					var res = new()
					res.move = move
					res.anim_name = "super_2"
					
					var cin = AttInfo.Cinema.new()
					cin.is_p2 = state.is_p2
					cin.show_opp = false
					cin.anim_name = "super_2_startup"
					cin.n_frames = move.att_info[0].n_cinematic_start
					#cin.move = move
					res.req_cinematic = cin
					state.bar_super -= 2000
					
					st.processed = true
					return res
		, true)
	else:
		return null

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		return CsIdle.new()

func dict4hash():
	return [ _STATE_NAME,
		
	]
