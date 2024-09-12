class_name CsTargetCombo extends _CsAttBase

const _STATE_NAME = "targetcombo"

const move_prio = 2


static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo):
#	var his = state.input_history
#	var n = 0
#	var move : DT.MoveInfo
#	for st : IN.InputState in his.his:
#		n += st.nf
#		if st.processed or n > sliceback:
#			return null
#		if not st.new_bt:
#			continue
	return _check_inputs(state, sliceback, func (st, n):
		var nms = [ st.name(false), st.name(true) ]
		for tar in allow.targets:
			var move = state._info.moves_tr[tar]
			if nms.has(move.cmd.command_str):
				var res = new()
				res.move = move
				res.anim_name = move.name
				
				st.processed = true
				return res
	)

func _init():
	pass

func init():
	pass

func check_next(state : PlayerState):
	var next = null
	if state_t == move.n_frames:
		return CsIdle.new()
	elif att_processed:
		var info = query_hit()
		if info.cancels:
			next = CsTargetCombo.try_next(state, state_t + 10, info.cancels)
		if next: return next

func deinit():
	pass
