class_name _CsBase

var state_t : int = 0
var next_state : String = ""
var next_offset : Vector2i
var anim_name : String = ""

func init():
	pass

func check_next(state : PlayerState):
	assert(false, "function must be implemented!")

func clone_next():
	assert(false, "function must be implemented!")

func _clone_next(res):
	res.state_t = state_t + 1
	res.next_state = ""
	return res

func deinit():
	pass

func step(state : PlayerState):
	assert(false, "function must be implemented!")

func get_anim_frame():
	return state_t

func query_hit():
	assert(false, "state does not implement query_hit!")

func query_stun():
	return ST.STUN_TY.NORMAL
