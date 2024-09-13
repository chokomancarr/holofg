class_name CsTargetCombo extends _CsAttBase

const _STATE_NAME = "targetcombo"

static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo):
	return _check_inputs(state, sliceback, func (st, n):
		var nms = st.names()
		for tar in allow.targets:
			var move = state._info.moves_tr[tar]
			if nms.has(move.cmd.command_str):
				var res = new()
				res.move = move
				res.anim_name = move.name.replace(".", "_")
				
				st.processed = true
				return res
	)

func init():
	pass

func check_next(state : PlayerState):
	var next = null
	if state_t == move.n_frames:
		return CsIdle.new()
	elif att_processed:
		var info = query_hit()
		if info.cancels:
			next = CsSpecial.try_next(state, state_t + 10, ST.CancelInfo.from_all())
			if next: return next
			
			next = CsTargetCombo.try_next(state, state_t + 10, info.cancels)
			if next: return next

func deinit():
	pass
