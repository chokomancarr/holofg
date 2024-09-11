class_name _CsAttBase extends _CsBase

var move : DT.MoveInfo
var current_att : int
var att_processed : bool
var att_part : ST.ATTACK_PART

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

func step(state : PlayerState):
    _step()
	state.boxes = []
	var found_att = false
	for b in move.boxes:
		var is_att = b.ty == ST.BOX_TY.HIT || b.ty == ST.BOX_TY.GRAB
		if b.frame_start <= state_t && b.frame_end >= state_t:
			state.boxes.push_back(b as ST.BoxInfo)
			if is_att and not found_att:
				found_att = true
			    att_part = ST.ATTACK_PART.ACTIVE
				current_att = b.hit_i
		elif is_att and not found_att:
			if b.frame_start > state.state_t:
				att_part = ST.ATTACK_PART.STARTUP
			else:
				att_part = ST.ATTACK_PART.RECOVERY
    att_processed = !found_att

func query_hit():
	return move.hit_info[current_att]

func query_stun():
    if att_part == ST.ATTACK_PART.RECOVERY:
        return ST.STUN_TY.PUNISH_COUNTER
    else:
        return ST.STUN_TY.COUNTER