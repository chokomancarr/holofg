class_name CsSuper1 extends _CsAttBase

const _STATE_NAME = "super_1"

var in_superfreeze = true

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[], []
	)

static func try_next(state : PlayerState, sliceback : int):
	if state.bar_super > 1000:
		return _check_inputs(state, sliceback, func (st, n, dd):
			var move = state._info.moves_su_1
			if move:
				if move.cmd.check(st, dd):
					var res = new()
					res.move = move
					res.anim_name = "super_1_startup"
					res.req_freeze = 60
					res.req_freeze_exclusive = true
					state.bar_super -= 1000
					
					st.processed = true
					return res
		, true)
	else:
		return null

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		return CsIdle.new()

func step(pst: PlayerState):
	super.step(pst)
	if in_superfreeze:
		in_superfreeze = false
		anim_name = "super_1"

func dict4hash():
	return [ _STATE_NAME,
		
	]

func get_anim_frame(df):
	if in_superfreeze:
		return df * 60
	else:
		return state_t
