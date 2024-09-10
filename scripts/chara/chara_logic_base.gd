class_name CharaLogic

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

func step(state : PlayerState, st_old : PlayerState, inputs : IN.InputState):
	if state.action_is_p2:
		inputs.val |= IN.DIR_FLIP_BIT
	else:
		inputs.val &= ~IN.DIR_FLIP_BIT
	
	state.input_history.push(inputs)
	
	if GameMaster.game_state.is_frozen():
		return
	
	state.state.step(state)
	state.pos += state.state.next_offset

static func apply_hit(p : PlayerState, hit_info: ST.HitInfo, ppldist : int):
	pass

static func _get_stun_ty(p : PlayerState):
	return ST.STUN_TY.NORMAL
