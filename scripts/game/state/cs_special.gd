class_name CsSpecial extends _CsAttBase

const _STATE_NAME = "special"

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[], []
	)

static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo):
	var sps = state._info.moves_sp.filter(func (m): return allow.can_sp(m.name))
	return _check_inputs(state, sliceback, func (st, n, dd):
		var alias = st.names()
		for move in sps:
			if alias.has(move.alias_name) or move.cmd.check(st, dd):
				var res = new()
				res.move = move
				res.anim_name = move.name
				
				st.processed = true
				return res
	, true)

func check_next(state : PlayerState):
	var next = null
	if state_t == move.n_frames:
		return CsIdle.new()

func dict4hash():
	return [ _STATE_NAME,
		
	]
