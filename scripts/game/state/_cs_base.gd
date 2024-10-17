class_name _CsBase

var state_t : int = 0
var next_offset : Vector2i
var anim_name : String = ""
var use_pos_flip : bool
var airborne : bool

var block_state : ST.BLOCK_TY

var attack_ty : AttInfo.TY

var push_wall : bool
var push_opp := true

var req_freeze : int = 0
var req_freeze_exclusive = false

var req_cinematic : MoveInfo.Cinema

var bounds_off : Vector2i

func _clone(res):
	return ObjUtil.clone(self, res,
		[ "state_t", "next_offset", "anim_name", "use_pos_flip", "airborne", "block_state", "attack_ty",
			"push_wall", "push_opp", "req_freeze", "bounds_off" ],
		[]
	)

static func _check_inputs(state : PlayerState, sliceback, callback, d = false):
	var his = state.input_history
	var dirs = his.dirs.duplicate(true) as Array if d else null
	var n = 0
	var move : MoveInfo
	for st : IN.InputState in his.his:
		n += st.nf
		var m = st.nf
		while d:
			var lst = dirs.pop_front()
			var f = lst.nf
			if f <= m:
				m -= f
				if m == 0:
					break
			else:
				lst.nf -= m
				dirs.push_front(lst)
				break
		if st.processed or n > sliceback:
			return null
		if not st.new_bt:
			continue
		var res = callback.call(st, n, dirs) if d else callback.call(st, n)
		if res:
			return res

func check_next(state : PlayerState):
	assert(false, "function must be implemented!")

func init(state : PlayerState):
	pass

func deinit(state : PlayerState):
	pass

func step(state : PlayerState):
	assert(false, "function must be implemented!")

func _step():
	state_t += 1
	next_offset = Vector2i.ZERO
	attack_ty = AttInfo.TY.NONE

func get_anim_frame(df):
	return state_t

func query_hit():
	assert(false, "state does not implement query_hit!")

func query_stun():
	return ST.STUN_TY.NORMAL

func get_frame_meter_color():
	return null

func _dict4hash():
	return [
		state_t,
		next_offset,
		#anim_name,
		use_pos_flip,
		airborne,
		block_state,
		attack_ty,
		push_wall,
		push_opp,
		req_freeze,
		bounds_off,
		dict4hash()
	]

func dict4hash():
	assert(false, "state does not implement dict4hash!")
