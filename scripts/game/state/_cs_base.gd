class_name _CsBase

var state_t : int = 0
var next_offset : Vector2i
var anim_name : String = ""
var use_pos_flip : bool

var push_wall : bool

var req_freeze : int = 0

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

func init():
	pass

func check_next(state : PlayerState):
	assert(false, "function must be implemented!")

func deinit():
	pass

func step(state : PlayerState):
	assert(false, "function must be implemented!")

func _step():
	state_t += 1
	next_offset = Vector2i.ZERO
	req_freeze = 0

func get_anim_frame(df):
	return state_t

func query_hit():
	assert(false, "state does not implement query_hit!")

func query_stun():
	return ST.STUN_TY.NORMAL

func get_frame_meter_color():
	return null
