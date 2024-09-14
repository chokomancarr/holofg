class_name CsStunAnim extends _CsBase

const _STATE_NAME = "stun_anim"
var n_stun : int

func _init(opp : PlayerState, info : ST.OppAnimInfo):
	anim_name = "opp/opp_" + opp.state.anim_name
	n_stun = info.nf
	state_t = opp.state.state_t

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

func get_frame_meter_color():
	return Color.YELLOW
