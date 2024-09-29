class_name _CsNeutralBase extends _CsBase

func check_actions(state : PlayerState, sliceback, att_only = false):
	var next = null
	next = CsSuper1.try_next(state, sliceback)
	if next: return next
	
	next = CsSpecial.try_next(state, sliceback, ST.CancelInfo.from_all())
	if next: return next
	
	next = CsNormal.try_next(state, sliceback, ST.CancelInfo.from_all())
	if next: return next
	
	next = CsGrab.try_next(state, sliceback)
	if next: return next
	
	if not att_only:
		next = CsParry.try_next(state)
		if next: return next
		
		next = CsDash.try_next(state)
		if next: return next
		
		next = CsJump.try_next(state)
		if next: return next

func query_stun():
	return ST.STUN_TY.NORMAL if block_state == ST.BLOCK_TY.NONE else ST.STUN_TY.BLOCK
