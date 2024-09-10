class_name CsNormal extends _CsBase

const _STATE_NAME = "normal"

var move : DT.MoveInfo
var current_att : int

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
	state.boxes = []
	var found_att = false
	for b in move.boxes:
		var is_att = b.ty == ST.BOX_TY.HIT || b.ty == ST.BOX_TY.GRAB
		if b.frame_start <= state_t && b.frame_end >= state_t:
			state.boxes.push_back(b as ST.BoxInfo)
			if is_att and not found_att:
				found_att = true
				#state.att_part = ST.ATTACK_PART.ACTIVE
				current_att = b.hit_i
		#elif is_att and not found_att:
			#if b.frame_start > state.state_t:
				#state.att_part = ST.ATTACK_PART.STARTUP
			#else:
				#state.att_part = ST.ATTACK_PART.RECOVERY

func get_anim_frame():
	return state_t

func query_hit():
	return move.hit_info[current_att]
