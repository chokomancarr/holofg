class_name CsAirNormal extends _CsAttBase

const _STATE_NAME = "airnormal"

const move_prio = 2
var jump_traj : DT.OffsetInfo
var jump_traj_off : int

static func try_next(state : PlayerState, sliceback : int, allow : ST.CancelInfo, jdir: int):
	var jx = "%d." % [ jdir + 7 ]
	var j8 = "8."
	return _check_inputs(state, sliceback, func (st, n):
		var nmx = st.name(false)
		var nm5 = st.name(true)
		for nrm in [jx + nmx, j8 + nmx, jx + nm5, j8 + nm5]:
			move = state._info.moves_j_nr.get(nrm)
			if move:
				if allow.can_anr(nrm):
					var res = new()
					res.move = move
					res.anim_name = move.name
					
					st.processed = true
					return res
	)

func _init():
	pass

func init():
	pass

func step():
	super.step()
	next_offset = jump_traj.eval(jump_traj_off + state_t - 1)

func check_next(state : PlayerState):
	var next = null
	if state.pos.y == 0:
		return CsLandRecovery.new(3)
	if att_processed:
		var info = query_hit()
		if info.cancels:
			next = CsTargetCombo.try_next(state, state_t + 10, info.cancels)
			if next: return next
			
			next = CsNormal.try_next(state, state_t + 10, info.cancels)
			if next: return next

func deinit():
	pass