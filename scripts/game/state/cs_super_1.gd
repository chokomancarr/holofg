class_name CsSuper1 extends _CsAttBase

const _STATE_NAME = "super_1"

var in_cinematic = true

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[], []
	)

static func try_next(state : PlayerState, sliceback : int):
	return _check_inputs(state, sliceback, func (st, n, dd):
		var move = state._info.moves_su_1
		if move:
			if move.cmd.check(st, dd):
				var res = new()
				res.move = move
				res.anim_name = "super_1_startup"
				res.req_freeze = 60
				res.req_freeze_exclusive = true
				
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
	if in_cinematic:
		in_cinematic = false
		anim_name = "super_1"

func dict4hash():
	return [ _STATE_NAME,
		
	]

func get_anim_frame(df):
	if in_cinematic:
		return df * 60
	else:
		return state_t
