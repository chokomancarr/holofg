class_name CsIdle extends _CsNeutralBase

const _STATE_NAME = "idle"

var standing = true

var first = true

static var _override_block_ty := ST.BLOCK_TY.NONE

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "standing", "first" ],
		[]
	)

func _init():
	anim_name = "5"
	use_pos_flip = true

func check_next(state : PlayerState):
	var next = null
	
	next = check_actions(state, 10 if state_t == 0 else 1)
	if next: return next
	
	next = CsWalk.try_next(state)
	if next: return next

func step(state : PlayerState):
	_step()
	
	var d = state.input_history.last_dir()
	if standing != (d > 3):
		standing = !standing
		anim_name = "5" if standing else "2"
		state_t = 0
	
	if _override_block_ty != ST.BLOCK_TY.NONE:
		block_state = _override_block_ty
	else:
		block_state = ST.BLOCK_TY.NONE if d > 1 else ST.BLOCK_TY.LOW
	
	state.boxes = [state._info.idle_box if standing else state._info.crouch_box] as Array[ST.BoxInfo]
	
	first = false
	
	#TODO: remove this
	if state_t == 5:
		state.bar_health = state._info.max_health

func get_anim_frame(df):
	return -1

func dict4hash():
	return [ _STATE_NAME,
		standing, first
	]
