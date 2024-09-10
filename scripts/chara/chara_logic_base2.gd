class_name CharaLogic2

static var common_moves : Array[DT.MoveInfo]
static var jump_moves : Array[DT.MoveInfo]
static var jump_offsets : Array[DT.OffsetInfo]
static var jump_cancel_info : ST.CancelInfo
static var jump_recovery_move : DT.MoveInfo

func _init():
	if not common_moves.size():
		_init_common_moves()

func _init_common_moves():
	var dash = DT.MoveInfo.new()
	dash.name = "66"
	dash.cmd = IN.InputCommand.from_string("66")
	dash.cmd.t_dirs = 10
	dash.n_frames = 20
	dash.offsets = DT.OffsetInfo.from_keys([ [0, Vector2i(50, 0)], [10, Vector2i(30, 0)] ], 20)
	common_moves.push_back(dash)
	
	var bdash = DT.MoveInfo.new()
	bdash.name = "44"
	bdash.cmd = IN.InputCommand.from_string("44")
	bdash.cmd.t_dirs = 10
	bdash.n_frames = 20
	bdash.offsets = DT.OffsetInfo.from_keys([ [0, Vector2i(-40, 0)], [10, Vector2i(-20, 0)] ], 20)
	common_moves.push_back(bdash)
	
	var _jumpcurve = []
	var _v = 1
	const _g = 10
	for i in range(18):
		#_jumpcurve.push_back([0, roundi(cos(PI * 0.5 * i / 17.0)) * 100])
		_jumpcurve.push_back([0, _v])
		_v += _g
	_jumpcurve.append_array([ [0, 0], [0, 0], [0, 0] ])
	_jumpcurve.reverse()
	for i in range(21):
		_jumpcurve.push_back([0, -_jumpcurve[20 - i][1]])
	
	jump_offsets = [
		DT.OffsetInfo.from_vals(_jumpcurve, 41),
		DT.OffsetInfo.from_vals(_jumpcurve, 41),
		DT.OffsetInfo.from_vals(_jumpcurve, 41)
	] as Array[DT.OffsetInfo]
	for i in range(41):
		jump_offsets[0].vals[i].x = -20
		jump_offsets[2].vals[i].x = 30

	var add_jump = func (i):
		var jump = DT.MoveInfo.new()
		jump.name = "8"
		jump.cmd = IN.InputCommand.from_string(str(i+7))
		jump.cmd.t_dirs = 2
		jump.n_frames = 40
		jump.offsets = jump_offsets[i]
		jump.can_hold = true
		jump.is_jump = true
		jump.force_att_part = ST.ATTACK_PART.STARTUP
		jump_moves.push_back(jump)

	add_jump.call(0)
	add_jump.call(1)
	add_jump.call(2)
	
	jump_cancel_info = ST.CancelInfo.new()
	jump_cancel_info.air_normals = true
	jump_cancel_info.air_specials = true
	jump_cancel_info.from_t = 5
	
	jump_recovery_move = DT.MoveInfo.new()
	jump_recovery_move.name = "8.recovery"
	jump_recovery_move.n_frames = 4
	jump_recovery_move.force_att_part = ST.ATTACK_PART.RECOVERY

var force_rename = false
var res_state : ST.STATE_TY

func step(state : ST.PlayerState, st_old : ST.PlayerState, inputs : IN.InputState):
	if state.action_is_p2:
		inputs.val |= IN.DIR_FLIP_BIT
	else:
		inputs.val &= ~IN.DIR_FLIP_BIT
	
	if inputs.val == state.input_history[0].val:
		state.input_history[0].nf += 1
		state.input_history[0].bt_just = false
	else:
		state.input_history.push_front(inputs)
		if state.input_history.size() > 30:
			state.input_history.pop_back()
	
	if GameMaster.game_state.is_frozen():
		if GameMaster.game_state.freeze_canbuffer and (state.state == ST.STATE_TY.ACTION) and not state.next_action:
			#if state.input_history[0].bt_just:
			if state.input_history[0].nf == 1:
				var mv = _find_next_move(state, st_old.current_action.hit_info[st_old.current_att].cancels)
				if mv:
					state.next_action = mv
			return
		else:
			return
	
	force_rename = false
	if state.state == ST.STATE_TY.ACTION:
		if state.state_t == state.current_action.n_frames - 1:
			state.state = ST.STATE_TY.IDLE_5
			force_rename = true
		elif state.check_land and state.pos.y == 0:
			state.check_land = false
			state.offset_dt = 0
			state.next_action = jump_recovery_move
	if state.stun_t > 0:
		if state.state_t == state.stun_t - 1:
			state.stun_t = 0
			state.state = ST.STATE_TY.IDLE_5
			force_rename = true
	
	if (state.state & ST.STATE_IDLE_BIT) > 0:
		state.action_is_p2 = state.pos_is_p2
	
	var mv = state.next_action
	
	if mv:
		force_rename = true
	else:
		var isfloor = state.pos.y > 0
		_proc_movement(state)
		if not isfloor and state.pos.y == 0:
			pass
	
	if (state.state & ST.STATE_IDLE_BIT) > 0:
		mv = _find_next_move(state, ST.CancelInfo.from_all())
	elif state.state == ST.STATE_TY.ACTION:
		if state.att_part == ST.ATTACK_PART.ACTIVE:
			mv = _find_next_move(state, state.current_action.hit_info[state.current_att].cancels)
		elif state.current_action.is_jump and state.state_t > jump_cancel_info.from_t:
			mv = _find_next_move(state, jump_cancel_info)
			if mv:
				force_rename = true
	
	if mv:
		state.state = ST.STATE_TY.ACTION
		state.current_action = mv
		state.action_name = mv.name
		state.next_action = null
		if mv.override_offsets:
			state.current_offsets = mv.offsets
		else:
			state.offset_dt = state.state_t + 1
	
	if st_old.state == state.state and not force_rename:
		state.state_t += 1
	else:
		state.state_t = 0
		_update_move_name(state)
	
	res_state = state.state
	
	_apply_movement(state)
	_get_boxes(state)

func _find_next_move(state : ST.PlayerState, allow : ST.CancelInfo):
	if not state.att_processed and not (allow.everything or allow.rapid) and not state.current_action.is_jump:
		return
	
	var last_input = state.input_history[0]
	var last_bts = last_input.bts()
	var l_nmx = last_input.name(false)
	var l_nm5 = last_input.name(true)
	
	var dir_history = [] as Array[IN.InputState]
	var last_dir = -1
	for h in state.input_history:
		var d2 = h.dir_flipped()
		if d2 == last_dir:
			dir_history[-1].nf += h.nf
		else:
			dir_history.push_back(IN.InputState.new(d2, h.nf, false))
			last_dir = d2
	
	var first_f = state.input_history[0].nf == 1
	
	if first_f:
		for move : DT.MoveInfo in state._info.moves_sp:
			if allow.can_sp(move.name):
				if move.cmd.check(dir_history, last_bts):
					return move
		
		for tar in allow.targets:
			var move = state._info.moves_tr[tar]
			if move.cmd.check(dir_history, last_bts, l_nmx):
				return move
		
		for nrm in [l_nmx, l_nm5]:
			var ok = false
			var move = state._info.moves_nr.get(nrm)
			if move:
				if allow.can_nr(nrm):# or (allow.rapid and nrm == state.action_name):
					return move
		
		if allow.air_normals:
			for jnr in [l_nmx, l_nm5]:
				var move = state._info.moves_j_nr.get("8." + jnr)
				if move:
					state.check_land = true
					return move
	
	if allow.everything:
		for com in common_moves:
			if first_f:
				if com.cmd.check(dir_history, last_bts, l_nmx):
					return com
		for jmp in jump_moves:
			if jmp.cmd.check(dir_history, last_bts, l_nmx):
				#state.check_land = true
				return jmp
	return null

func step_post(state : ST.PlayerState, st_old : ST.PlayerState):
	if res_state != state.state:
		state.state_t = 0
		_update_move_name(state)
		_get_boxes(state)
	
	if state.att_processed and (state.state != ST.STATE_TY.ACTION or state.att_part != ST.ATTACK_PART.ACTIVE):
		state.att_processed = false

func _proc_movement(state : ST.PlayerState):
	if (state.state & ST.STATE_IDLE_BIT) > 0:
		var d = state.input_history[0].dir_flipped()
		state.state = ST.STATE_TY.IDLE_5 if d == 5\
			else ST.STATE_TY.CROUCH_2 if d == 2 || d == 3\
			else ST.STATE_TY.CROUCH_BACK_2 if d == 1\
			else ST.STATE_TY.WALK_FWD_6 if d == 6\
			else ST.STATE_TY.WALK_BACK_4 if d == 4\
			else ST.STATE_TY.IDLE_5

func _apply_movement(state : ST.PlayerState):
	match state.state:
		ST.STATE_TY.WALK_FWD_6:
			state.pos.x += -state._info.walk_sp_rev if state.action_is_p2 else state._info.walk_sp_fwd
		ST.STATE_TY.WALK_BACK_4:
			state.pos.x += state._info.walk_sp_fwd if state.action_is_p2 else -state._info.walk_sp_rev
		ST.STATE_TY.ACTION, ST.STATE_TY.STUN:
			if state.current_offsets:
				state.pos += state.current_offsets.eval(state.state_t + state.offset_dt)
		_:
			pass

func _get_boxes(state : ST.PlayerState):
	match state.state:
		ST.STATE_TY.IDLE_5, ST.STATE_TY.WALK_FWD_6, ST.STATE_TY.WALK_BACK_4,\
		ST.STATE_TY.STUN, ST.STATE_TY.BLOCK_5b:
			state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]
		ST.STATE_TY.CROUCH_2, ST.STATE_TY.CROUCH_BACK_2, ST.STATE_TY.BLOCK_CROUCH_2b:
			state.boxes = [state._info.crouch_box] as Array[ST.BoxInfo]
		ST.STATE_TY.ACTION:
			if state.current_action.force_att_part != ST.ATTACK_PART.NONE:
				state.att_part = state.current_action.force_att_part
			else:
				state.boxes = []
				var found_att = false
				for b in state.current_action.boxes:
					var is_att = b.ty == ST.BOX_TY.HIT || b.ty == ST.BOX_TY.GRAB
					if b.frame_start <= state.state_t && b.frame_end >= state.state_t:
						state.boxes.push_back(b as ST.BoxInfo)
						if is_att and not found_att:
							found_att = true
							state.att_part = ST.ATTACK_PART.ACTIVE
							state.current_att = b.hit_i
					elif is_att and not found_att:
						if b.frame_start > state.state_t:
							state.att_part = ST.ATTACK_PART.STARTUP
						else:
							state.att_part = ST.ATTACK_PART.RECOVERY
		_:
			pass

func _update_move_name(state : ST.PlayerState):
	match state.state:
		ST.STATE_TY.ACTION:
			state.move_name = state.action_name.replace(".", "_")
		ST.STATE_TY.STUN:
			state.move_name = "stun_%s_%s" % [ "st" if state.stun_standing else "cr", ST.STUN_DIR.find_key(state.stun_dir).to_lower() ]
		_:
			var nm1 : String = ST.STATE_TY.find_key(state.state)
			var spl1 = nm1.rsplit("_", false, 1)
			state.move_name = spl1[1]

static func apply_hit(p : ST.PlayerState, hit_info: ST.HitInfo, ppldist : int):
	var ty = _get_stun_ty(p)
	var block = p.state == ST.STATE_TY.WALK_BACK_4 || p.state == ST.STATE_TY.CROUCH_BACK_2
	var n_stun = hit_info.stun_block
	if block:
		p.state = ST.STATE_TY.BLOCK_CROUCH_2b if p.state == ST.STATE_TY.CROUCH_BACK_2 else ST.STATE_TY.BLOCK_5b
	else:
		p.boxes = [ p._info.idle_box ]
		p.state = ST.STATE_TY.STUN
		n_stun = hit_info.stun_hit
		p.stun_standing = true
		p.stun_dir = ST.STUN_DIR.HEAD
		if hit_info.push_hit > 0 || hit_info.min_space > 0:
			var push = hit_info.push_hit if ppldist > hit_info.min_space else hit_info.min_space
			var p1 = floori(push / (2 * n_stun))
			var p0 = push - p1 * n_stun
			p.current_offsets = DT.OffsetInfo.from_keys([[1, [p0 + p1, 0]], [2, [p1, 0]], [n_stun, [0, 0]]], n_stun + 5)
		else:
			p.current_offsets = null
		match ty:
			ST.STUN_TY.COUNTER:
				n_stun += 2
			ST.STUN_TY.PUNISH_COUNTER:
				n_stun += 4
			_:
				pass
	p.stun_t = n_stun
	p.state_t = 0

static func _get_stun_ty(p : ST.PlayerState):
	match p.state:
		ST.STATE_TY.ACTION:
			match p.att_part:
				ST.ATTACK_PART.RECOVERY:
					return ST.STUN_TY.PUNISH_COUNTER
				_:
					return ST.STUN_TY.COUNTER
		_:
			return ST.STUN_TY.NORMAL
