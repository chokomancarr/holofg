class_name CsSuperEnd extends _CsBase

const _STATE_NAME = "super_end"
var move : MoveInfo._Base
var is_opp : bool

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "move", "is_opp" ],
		[]
	)

func _init(p : PlayerState = null, move : MoveInfo._Base = null, is_opp = false):
	if p:
		self.move = move
		self.is_opp = is_opp
		use_pos_flip = true
		anim_name = "opp/opp_super_2_end" if is_opp else "super_2_end"

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		if is_opp:
			return CsStunAir.new(state, ST.STUN_AIR_TY.LIM_JUGGLE) if state.pos.y > 0 else CsKnockRecover.new()
		else:
			return CsIdle.new()

func step(state : PlayerState):
	_step()
	state.boxes = []

func get_frame_meter_color():
	return Color.YELLOW if is_opp else Color.NAVY_BLUE

func dict4hash():
	return [ _STATE_NAME,
		move.uid, is_opp
	]
