class_name CsIdle extends _CsBase

const _STATE_NAME = "idle"

var standing = true

var first = true

func _init():
	anim_name = "5"
	use_pos_flip = true

func init():
	pass

func check_next(state : PlayerState):
	var next = null
	next = CsSpecial.try_next(state, 10 if first else 1, ST.CancelInfo.from_all())
	if next: return next
	
	next = CsNormal.try_next(state, 10 if first else 1, ST.CancelInfo.from_all())
	if next: return next
	
	next = CsDash.try_next(state)
	if next: return next
	
	next = CsJump.try_next(state)
	if next: return next
	
	next = CsWalk.try_next(state)
	if next: return next

func deinit():
	pass

func step(state : PlayerState):
	_step()
	
	var d = state.input_history.last_dir()
	if standing != (d > 3):
		standing = !standing
		anim_name = "5" if standing else "2"
		state_t = 0
	
	state.boxes = [state._info.idle_box if standing else state._info.crouch_box] as Array[ST.BoxInfo]
	
	first = false

func get_anim_frame(df):
	return -1
