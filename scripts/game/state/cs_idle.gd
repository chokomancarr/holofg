class_name CsIdle extends _CsBase

const _STATE_NAME = "idle"

var standing = true

static func try_next(state : PlayerState):
	var d = state.input_history.last_dir()
	var b = state.input_history.last_bts()
	
	if b == 0 and (d < 4 or d == 5):
		return new()

func _init():
	anim_name = "5"

func init():
	pass

func check_next(state : PlayerState):
	var next = null
	next = CsNormal.try_next(state, ST.CancelInfo.from_all())
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

func get_anim_frame():
	return -1
