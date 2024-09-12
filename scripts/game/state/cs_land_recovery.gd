class_name CsLandRecovery extends _CsBase

const _STATE_NAME = "landrecovery"

var n_recovery : int

func _init(n):
	self.n_recovery = n
	anim_name = "8.recovery"

func init():
	pass

func check_next(state : PlayerState):
	if state_t == n_recovery:
		return CsIdle.new()

func deinit():
	pass

func step(state : PlayerState):
	_step()
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

func query_stun():
	return ST.STUN_TY.PUNISH_COUNTER

func get_anim_frame():
	return (state_t * 60) / n_recovery