class_name CsKnock extends _CsStunBase

const _STATE_NAME = "knock"
const N_FRAME = 20
const N_KNOCKED = 10

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[], []
	)

func _init(p : PlayerState = null, info : AttInfo.Hit = null):
	if p:
		state_t = 1
		anim_name = "knock_normal"

func check_next(state : PlayerState):
	if state_t == N_FRAME + N_KNOCKED:
		return CsKnockRecover.new()

func step(state : PlayerState):
	_step()
	state.boxes = []

func get_frame_meter_color():
	return Color.YELLOW

func get_anim_frame(df):
	if state_t == 1:
		return df
	else:
		return minf(((state_t - 1.0 + df) * 59.0) / N_FRAME, 60.0)

func dict4hash():
	return [ _STATE_NAME
	]
