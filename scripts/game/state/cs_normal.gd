class_name CsNormal extends _CsAttBase

const _STATE_NAME = "normal"

static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo):
	return _check_inputs(state, sliceback, func (st, n):
		for nrm in st.names(true):
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
			next = CsSpecial.try_next(state, 10, ST.CancelInfo.from_all())
			if next: return next
			
			next = CsTargetCombo.try_next(state, 10, info.cancels)
			if next: return next
			
			next = CsNormal.try_next(state, 10, info.cancels)
			if next: return next
