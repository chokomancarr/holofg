class_name CsOppAnim extends _CsBase

const _STATE_NAME = "stun_anim"
var info : AttInfo.Cinema

var pos0 : Vector2i

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "info", "pos0" ],
		[]
	)

func _init(opp : PlayerState = null, info : AttInfo.Cinema = null):
	if opp:
		anim_name = "opp/opp_" + opp.state.anim_name
		self.info = info
		state_t = opp.state.state_t
		pos0 = opp.pos
		push_opp = false

func check_next(state : PlayerState):
	if state_t == info.n_anim_end_opp:
		return CsKnockRecover.new()

func step(state : PlayerState):
	_step()
	state.boxes = []
	if info.end_bounds_offset_opp:
		bounds_off += info.end_bounds_offset_opp.eval(state_t - 1)

func deinit(state : PlayerState):
	var dp = info.end_dpos
	if not state.action_is_p2:
		dp.x *= -1
	state.pos = pos0 + dp

func get_frame_meter_color():
	return Color.YELLOW


func dict4hash():
	return [ _STATE_NAME,
		pos0
	]
