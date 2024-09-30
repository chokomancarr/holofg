class_name CsSuperEnd extends _CsBase

const _STATE_NAME = "super_end"
var info : ST.AttInfo_Super
var is_opp : bool
var n_frames : int

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[  ],
		[]
	)

func _init(p : PlayerState = null, info: ST.AttInfo_Super = null, is_opp = false):
	if p:
		self.info = info
		self.is_opp = is_opp
		self.n_frames = info.n_end_opp if is_opp else info.n_end
		use_pos_flip = true
		anim_name = ("opp/opp_super_2_end" if info.end_opp_use_anim else "knocked") if is_opp else "super_2_end"

func check_next(state : PlayerState):
	if state_t == n_frames:
		return CsKnockRecover.new() if is_opp else CsIdle.new()

func step(state : PlayerState):
	_step()
	state.boxes = []

func get_frame_meter_color():
	return Color.YELLOW if is_opp else Color.NAVY_BLUE

func dict4hash():
	return [ _STATE_NAME
	]
