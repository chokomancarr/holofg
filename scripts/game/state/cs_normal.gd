class_name CsNormal extends _CsAttBase

const _STATE_NAME = "normal"

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[], []
	)

static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo):
	return _check_inputs(state, sliceback, func (st, n):
		for nrm in st.names(true, false):
			var move = state._info.moves_nr.get(nrm)
			if move:
				if allow.can_nr(nrm):
					var res = new()
					res.move = move
					res.anim_name = move.name
					
					st.processed = true
					return res
	)

func check_next(state : PlayerState):
	var next = null
	if state_t == move.n_frames:
		return CsIdle.new()
	elif att_processed:
		var info = query_hit()
		if info.cancels:
			if state.can_super:
				if info.cancels.super_2:
					next = CsSuper2.try_next(state, 10)
					if next: return next
				if info.cancels.super_1:
					next = CsSuper1.try_next(state, 10)
					if next: return next
			
			next = CsSpecial.try_next(state, 10, info.cancels)
			if next: return next
			
			next = CsTargetCombo.try_next(state, 10, info.cancels)
			if next: return next
			
			next = CsNormal.try_next(state, 10, info.cancels)
			if next: return next

func dict4hash():
	return [ _STATE_NAME,
		
	]
