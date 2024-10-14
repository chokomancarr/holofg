class_name CsJump extends _CsBase

const _STATE_NAME = "jump"

var dir: int
var offsets : DT.OffsetInfo

var aerial : bool
 
func clone():
	return ObjUtil.clone(self, _clone(new(dir)),
		[ "dir", "offsets", "aerial" ],
		[]
	)

static var _jump_offsets = (func ():
	var _jumpcurve = []
	var _v = 1
	const _g = 7
	for i in range(18):
		_jumpcurve.push_back([0, _v])
		_v += _g
	_jumpcurve.append_array([ [0, 0], [0, 0], [0, 0] ])
	_jumpcurve.reverse()
	for i in range(21):
		_jumpcurve.push_back([0, -_jumpcurve[20 - i][1]])
	var jump_offsets = [
		DT.OffsetInfo.from_vals(_jumpcurve, 43),
		DT.OffsetInfo.from_vals(_jumpcurve, 43),
		DT.OffsetInfo.from_vals(_jumpcurve, 43)
	] as Array[DT.OffsetInfo]
	for i in range(41):
		jump_offsets[0].vals[i].x = -20
		jump_offsets[2].vals[i].x = 30
	return jump_offsets
).call()

static func try_next(state : PlayerState):
	var d = state.input_history.last_dir()
	if d > 6:
		return new(d - 7)

func _init(dir):
	self.dir = dir
	offsets = _jump_offsets[dir]
	anim_name = "8" #str(dir + 7)
	airborne = true

func check_next(state : PlayerState):
	var next = null
	if state_t == 40:
		return CsIdle.new()
	else:
		if state_t > 4:
			next = CsAirNormal.try_next(state, 6, ST.CancelInfo.from_all(), dir)
			if next:
				next.jump_traj = offsets
				next.jump_traj_off = state_t
				return next

func step(state : PlayerState):
	_step()
	aerial = state_t > 2 && state_t < 39
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]
	next_offset = offsets.eval(state_t)

func get_frame_meter_color():
	return Color.LIGHT_BLUE if aerial else Color.GREEN_YELLOW

func dict4hash():
	return [ _STATE_NAME,
		dir, offsets.hashed()
	]
