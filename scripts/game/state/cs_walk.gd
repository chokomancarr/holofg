class_name CsWalk extends _CsBase

const _STATE_NAME = "walk"

var fwd = true

static func try_next(state : PlayerState):
	var d = state.input_history.last_dir()
	if d == 4 or d == 6:
		return new()

func _init():
	anim_name = "6"
	use_pos_flip = true

func init():
	pass

func check_next(state : PlayerState):
	var next = null
	next = CsNormal.try_next(state, 1, ST.CancelInfo.from_all())
	if next: return next
	
	var lbt = state.input_history.last_bts()
	var ldir = state.input_history.last_dir()
	if lbt != 0 or (ldir != 4 and ldir != 6):
		return CsIdle.new()

func deinit():
	pass

func step(state : PlayerState):
	_step()
	var d = state.input_history.last_dir()
	if fwd != (d > 5):
		fwd = !fwd
		anim_name = "6" if fwd else "4"
		state_t = 0
	
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]
	next_offset.x = state._info.walk_sp_fwd if fwd else -state._info.walk_sp_rev

func get_anim_frame(df):
	return -1
