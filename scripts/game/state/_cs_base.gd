class_name _CsBase

var state_t : int = 0
var next_offset : Vector2i
var anim_name : String = ""
var use_pos_flip : bool
var airborne : bool

var block_state : ST.BLOCK_TY

var attack_ty : ST.ATTACK_TY

var push_wall : bool

var req_freeze : int = 0

var bounds_off : Vector2i

static func _check_inputs(state, sliceback, callback):
	var his = state.input_history
	var n = 0
	var move : DT.MoveInfo
	for st : IN.InputState in his.his:
		n += st.nf
		if st.processed or n > sliceback:
			return null
		if not st.new_bt:
			continue
		var res = callback.call(st, n)
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
	req_freeze = 0
	attack_ty = ST.ATTACK_TY.NONE

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
		req_freeze,
		bounds_off,
		dict4hash()
	]

func dict4hash():
	assert(false, "state does not implement dict4hash!")
