class_name CsGrabOpp extends _CsBase

const _STATE_NAME = "stun_anim"
var info : ST.AttInfo_Grab

var pos0 : Vector2i

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "info", "pos0" ],
		[]
	)

func _init(opp : PlayerState = null, info : ST.AttInfo_Grab = null):
	if opp:
		anim_name = "opp/opp_" + opp.state.anim_name
		self.info = info
		state_t = opp.state.state_t
		pos0 = opp.pos
		push_opp = false

func check_next(state : PlayerState):
	if state_t == info.opp_nf:
		return CsKnockRecover.new()

func step(state : PlayerState):
	_step()
	state.boxes = []
	bounds_off += info.bounds_offset.eval(state_t - 1)

func deinit(state : PlayerState):
	state.pos = pos0 + Vector2i(info.end_dpos if state.action_is_p2 else -info.end_dpos, 0)

func get_frame_meter_color():
	return Color.YELLOW


func dict4hash():
	return [ _STATE_NAME,
		pos0
	]
