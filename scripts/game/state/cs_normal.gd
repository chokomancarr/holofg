class_name CsNormal extends _CsBase

const _STATE_NAME = "normal"

var move : DT.MoveInfo

static func try_next(state : PlayerState, allow : ST.CancelInfo):
	var last_input = state.input_history.history[0]
	var last_bts = last_input.bts()
	var l_nmx = last_input.name(false)
	var l_nm5 = last_input.name(true)
	
	var first_f = last_input.nf == 1
	
	if first_f:
		for nrm in [l_nmx, l_nm5]:
			var ok = false
			var move : DT.MoveInfo = state._info.moves_nr.get(nrm)
			if move:
				if allow.can_nr(nrm):
					var res = new()
					res.move = move
					res.anim_name = move.name
					return res

func clone_next():
	return _clone_next(ObjUtil.clone(self, new()))

func _init():
	pass

func init():
	pass

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		return CsIdle.new()

func deinit():
	pass

func step(state : PlayerState):
	
	
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

func get_anim_frame():
	return state_t
