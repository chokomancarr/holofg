class_name _CsAttBase extends _CsBase

var move : DT.MoveInfo
var current_att : int
var att_processed : bool
var att_part : ST.ATTACK_PART

func _clone(res):
	return ObjUtil.clone(self, super._clone(res),
		[ "move", "current_att", "att_processed", "att_part" ],
		[]
	)

func step(state : PlayerState):
	_step()
	state.boxes = []
	var found_att = false
	var has_att = false
	for b in move.boxes:
		var is_grab = b.ty == ST.BOX_TY.GRAB
		var is_att = b.ty == ST.BOX_TY.HIT || is_grab
		if b.frame_start <= state_t && b.frame_end >= state_t:
			state.boxes.push_back(b as ST.BoxInfo)
			if is_att and not has_att:
				has_att = true
				found_att = true
				att_part = ST.ATTACK_PART.ACTIVE
				current_att = b.hit_i
				attack_ty = query_hit().ty
		elif is_att and not found_att:
			if b.frame_start > state_t:
				att_part = ST.ATTACK_PART.STARTUP
			else:
				att_part = ST.ATTACK_PART.RECOVERY
			found_att = true
	if not has_att:
		att_processed = false
	
	if move.spawn_info.size() > 0:
		att_part = ST.ATTACK_PART.STARTUP if move.spawn_info.all(func (s): return s.frame >= state_t) else ST.ATTACK_PART.RECOVERY

	if move.offsets:
		next_offset = move.offsets.eval(state_t - 1)

func query_hit():
	return move.att_info[current_att]

func query_stun():
	if att_part == ST.ATTACK_PART.RECOVERY:
		return ST.STUN_TY.PUNISH_COUNTER
	else:
		return ST.STUN_TY.COUNTER

func get_frame_meter_color():
	match att_part:
		ST.ATTACK_PART.STARTUP:
			return Color.LIME_GREEN
		ST.ATTACK_PART.ACTIVE:
			return Color.RED
		ST.ATTACK_PART.RECOVERY:
			return Color.ROYAL_BLUE

func dict4hash():
	return [
		move.uid, current_att, att_processed, att_part, dict4hash2()
	]

func dict4hash2():
	assert(false, "not implemented!")
