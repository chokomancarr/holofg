class_name SummonState

var _info: DT.SummonInfo

var state_t : int = 0
var hit_cd : int = 0

var pos : Vector2i
var next_offset : Vector2i
var last_tick = false

func clone():
	return ObjUtil.clone(self, new(),
		[ "_info", "state_t", "hit_cd", "pos", "next_offset", "last_tick" ],
		[]
	)

func _init(pst : PlayerState = null, info : DT.SummonInfo = null):
	if pst:
		_info = info
		pos = pst.pos + _info.init_pos

func step():
	state_t += 1
	last_tick = (state_t == _info.lifetime)
	next_offset = _info.velocity
	if _info.offsets:
		next_offset += _info.offsets.eval(state_t - 1)

func dict4hash():
	return [
		_info.uid, state_t, hit_cd, pos, next_offset, last_tick
	]
