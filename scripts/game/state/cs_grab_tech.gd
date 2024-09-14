class_name CsGrabTech extends _CsBase

const _STATE_NAME = "grab_tech"
const N_FRAME = 40

var offsets = DT.OffsetInfo.from_keys([
	[0, [-80, 0]], [7, [-10, 0]], [10, [0, 0]]
], 40)

func _init():
	anim_name = "g_break"

func check_next(state : PlayerState):
	if state_t == N_FRAME:
		return CsIdle.new()

func step(state : PlayerState):
	_step()
	next_offset = offsets.eval(state_t - 1)

func get_frame_meter_color():
	return Color.CADET_BLUE
