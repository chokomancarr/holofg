class_name CsSpecial extends _CsAttBase

const _STATE_NAME = "special"

static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo):
	return _check_inputs(state, sliceback, func (st, n):
		var alias = st.names()
		for move in state._info.moves_sp:
			if alias.has(move.alias_name):
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

func deinit():
	pass