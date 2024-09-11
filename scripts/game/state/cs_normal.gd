class_name CsNormal extends _CsAttBase

const _STATE_NAME = "normal"

const move_prio = 2

static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo):
	var his = state.input_history
	if his.bts[0].nf == 1:
		for nrm in [his.sx, his.s5]:
			var ok = false
			var move : DT.MoveInfo = state._info.moves_nr.get(nrm)
			if move:
				if allow.can_nr(nrm):
					var res = new()
					res.move = move
					res.anim_name = move.name
					return res

func _init():
	pass

func init():
	pass

func check_next(state : PlayerState):
	var next = null
	if state_t == move.n_frames:
		return CsIdle.new()
	elif att_processed and info.cancels:
		var info = query_hit()
		next = CsNormal.try_next(state, 0, info.cancels)
		if next: return next

func deinit():
	pass
