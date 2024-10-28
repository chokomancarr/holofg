class_name CsStun extends _CsStunBase

const _STATE_NAME = "stun"
var n_stun : int

var standing : bool

var offsets : DT.OffsetInfo

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "n_stun", "standing", "offsets" ],
		[]
	)

func _init(p : PlayerState = null, info : AttInfo = null, no_offset = false, stdg = true):
	if p:
		state_t = 1
		standing = stdg
		var dr = ST.STUN_DIR.find_key(info.dir).to_lower()
		if not standing and dr == "body":
			dr = "head"
		anim_name = "stun_%s_%s" % [
			"st" if standing else "cr", dr
		]
		n_stun = info.stun_hit
		use_pos_flip = true
		push_wall = true
	
		if not no_offset and (info.push_hit != 0 || info.min_space > 0):
			var pushmin = maxi(info.min_space - absi(p.dist_to_opp.x), 0)
			var p1 = floori(info.push_hit / (2 * n_stun))
			var p0 = info.push_hit - p1 * n_stun
			offsets = DT.OffsetInfo.from_keys([[1, [-pushmin - p0 - p1, 0]], [2, [-p1, 0]], [n_stun, [0, 0]]], n_stun + 5)

func check_next(state : PlayerState):
	if state_t == n_stun:
		return CsIdle.new()

func step(state : PlayerState):
	_step()
	use_pos_flip = false
	state.boxes = [state._info.idle_box if standing else state._info.crouch_box] as Array[ST.BoxInfo]
	if offsets:
		next_offset = offsets.eval(state_t - 1)

func get_anim_frame(df):
	if state_t == 1:
		return df
	else:
		return ((state_t - 1.0 + df) * 59.0) / n_stun

func get_frame_meter_color():
	return Color.YELLOW

func dict4hash2():
	return [ _STATE_NAME,
		n_stun, standing, offsets.hashed() if offsets else 0
	]
