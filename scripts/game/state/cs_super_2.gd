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
					
					res.req_cinematic = move.cine_startup
					state.bar_super -= 2000
					
					st.processed = true
					return res
		, true)
	else:
		return null

func on_att_connected():
	pass

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		return CsIdle.new()

func dict4hash():
	return [ _STATE_NAME,
		
	]
