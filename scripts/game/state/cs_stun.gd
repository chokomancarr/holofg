class_name CsStun extends _CsBase

const _STATE_NAME = "stun"
var n_stun : int

static func try_next(state : PlayerState):
	return null

func _init(p : PlayerState, info : ST.HitInfo):
	anim_name = "stun"
	n_stun = info.stun_hit

func init():
	pass

func check_next(state : PlayerState):
	if state_t == n_stun:
		return CsIdle.new()

func deinit():
	pass

func step(state : PlayerState):
    _step()
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

