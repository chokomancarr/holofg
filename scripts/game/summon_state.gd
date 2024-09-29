class_name SummonState

var _info: DT.SummonInfo

var sm_hash: int

var state_t : int = 0
var hit_i : int = 0
var hit_cd : int = 0
var is_p2 : bool

var pos : Vector2i
var next_offset : Vector2i
var last_tick = false

func clone():
	return ObjUtil.clone(self, new(),
		[ "_info", "sm_hash", "state_t", "hit_i", "hit_cd", "is_p2", "pos", "next_offset", "last_tick" ],
		[]
	)

func _init(pst : PlayerState = null, info : DT.SummonInfo = null, uid : int = 0):
	if pst:
		_info = info
		pos = _info.init_pos
		if pst.action_is_p2:
			pos.x *= -1
		pos += pst.pos
		is_p2 = pst.action_is_p2
		sm_hash = (info.uid << 16) + uid

func step():
	state_t += 1
	last_tick = (state_t == _info.lifetime)
	next_offset = _info.velocity
	if _info.offsets:
		next_offset += _info.offsets.eval(state_t - 1)
	if hit_cd > 0:
		hit_cd -= 1

func dict4hash():
	return [
		_info.uid, sm_hash, state_t, hit_i, hit_cd, is_p2, pos, next_offset, last_tick
	]

func on_hit():
	hit_i += 1
	if hit_i < _info.n_hits:
		hit_cd += _info.hit_rate
	else:
		last_tick = true
