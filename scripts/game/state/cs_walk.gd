class_name CsWalk extends _CsNeutralBase

const _STATE_NAME = "walk"

var fwd = true

static func try_next(state : PlayerState):
	var d = state.input_history.last_dir()
	if d == 4 or d == 6:
		return new()

func _init():
	anim_name = "6"
	use_pos_flip = true

func check_next(state : PlayerState):
	var next = null
	
	next = check_actions(state, 10 if state_t == 0 else 1)
	if next: return next
	
	var lbt = state.input_history.last_bts()
	var ldir = state.input_history.last_dir()
	if ldir != 4 and ldir != 6:
		return CsIdle.new()

func step(state : PlayerState):
	_step()
	var d = state.input_history.last_dir()
	if fwd != (d > 5):
		fwd = !fwd
		anim_name = "6" if fwd else "4"
		state_t = 0
	
	block_state = ST.BLOCK_TY.NONE if fwd else ST.BLOCK_TY.HIGH
	
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]
	next_offset.x = state._info.walk_sp_fwd if fwd else -state._info.walk_sp_rev

func get_anim_frame(df):
	return -1
