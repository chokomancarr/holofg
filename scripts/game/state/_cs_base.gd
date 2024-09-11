class_name _CsBase

var state_t : int = 0
var next_offset : Vector2i
var anim_name : String = ""

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

func get_anim_frame():
	return state_t - 1

func query_hit():
	assert(false, "state does not implement query_hit!")

func query_stun():
	return ST.STUN_TY.NORMAL
