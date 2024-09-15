class_name CsKnockRecover extends _CsBase

const _STATE_NAME = "knockrecover"

var n_recovery : int

func _init():
	self.n_recovery = 20
	anim_name = "rise_5"

func check_next(state : PlayerState):
	if state_t == n_recovery:
		return CsIdle.new()

func step(state : PlayerState):
	_step()
	state.boxes = []
	#state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

func get_anim_frame(df):
	return ((state_t - 1 + df) * 60) / n_recovery
	
func get_frame_meter_color():
	return Color.YELLOW
