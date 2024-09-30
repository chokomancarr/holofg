class_name CsSuper2 extends _CsAttBase

const _STATE_NAME = "super_2"
var move : DT.MoveInfo

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[], []
	)

static func try_next(state : PlayerState, sliceback : int):
	return _check_inputs(state, sliceback, func (st, n, dd):
		var move = state._info.moves_su_2
		if move:
			if move.cmd.check(st, dd):
				var res = new()
				res.move = move
				res.anim_name = "super_2"
				
				var cin = CinematicInfo.new()
				cin.is_p2 = state.is_p2
				cin.show_opp = false
				cin.anim_name = "super_2_startup"
				cin.n_frames = move.n_cinematic_start
				res.req_cinematic = cin
				
				st.processed = true
				return res
	, true)

func check_next(state : PlayerState):
	var next = null
	if state_t == move.n_frames:
		return CsIdle.new()
	elif att_processed:
		var info = query_hit()
		if info.cancels:
			next = CsSpecial.try_next(state, 10, ST.CancelInfo.from_all())
			if next: return next
			
			next = CsTargetCombo.try_next(state, 10, info.cancels)
			if next: return next
			
			next = CsNormal.try_next(state, 10, info.cancels)
			if next: return next

func step(pst: PlayerState):
	super.step(pst)
	if in_superfreeze:
		in_superfreeze = false
		anim_name = "super_1"

func dict4hash():
	return [ _STATE_NAME,
		
	]

func get_anim_frame(df):
	if in_superfreeze:
		return df * 60
	else:
		return state_t
