class_name CsJump extends _CsBase

const _STATE_NAME = "jump"

const move_prio = 1

var dir: int
var move : DT.MoveInfo

static var _jump_moves = (func ():
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
	var jump_offsets = [
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
		return jump
	return [
		add_jump.call(0),
		add_jump.call(1),
		add_jump.call(2)
	]
).call()

static func try_next(state : PlayerState):
	#if state.input_history.his[0].nf > 1:
	#	return null
	
	for i in range(3):
		if _jump_moves[i].cmd.check(state.input_history):
			return new(i)

func _init(dir):
	self.dir = dir
	move = _jump_moves[dir]
	anim_name = move.name

func init():
	pass

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		return CsIdle.new()

func deinit():
	pass

func step(state : PlayerState):
	_step()
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]
	next_offset = move.offsets.eval(state_t - 1)
