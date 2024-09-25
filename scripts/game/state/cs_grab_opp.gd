class_name CsGrabOpp extends _CsBase

const _STATE_NAME = "stun_anim"
var info : ST.AttInfo_Grab

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "info" ],
		[]
	)

func _init(opp : PlayerState, info : ST.AttInfo_Grab):
	anim_name = "opp/opp_" + opp.state.anim_name
	self.info = info
	state_t = opp.state.state_t

func check_next(state : PlayerState):
	if state_t == info.opp_nf:
		return CsKnockRecover.new()

func step(state : PlayerState):
	_step()
	state.boxes = []
	bounds_off += info.bounds_offset.eval(state_t - 1)

func deinit(state : PlayerState):
	state.pos.x += info.end_dpos if state.action_is_p2 else -info.end_dpos

func get_frame_meter_color():
	return Color.YELLOW


func dict4hash():
	return [ _STATE_NAME
	]
