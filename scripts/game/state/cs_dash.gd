class_name CsDash extends _CsBase

const _STATE_NAME = "dash"

const move_prio = 1

var fwd = true
var move : DT.MoveInfo

static var move_fwd : DT.MoveInfo = (func ():
	var dash = DT.MoveInfo.new()
	dash.name = "66"
	dash.cmd = IN.InputCommand.from_string("66")
	dash.cmd.t_dirs = 10
	dash.n_frames = 20
	dash.offsets = DT.OffsetInfo.from_keys([ [0, Vector2i(50, 0)], [10, Vector2i(30, 0)] ], 20)
	return dash
).call()

static var move_rev : DT.MoveInfo = (func ():
	var dash = DT.MoveInfo.new()
	dash.name = "66"
	dash.cmd = IN.InputCommand.from_string("66")
	dash.cmd.t_dirs = 10
	dash.n_frames = 20
	dash.offsets = DT.OffsetInfo.from_keys([ [0, Vector2i(50, 0)], [10, Vector2i(30, 0)] ], 20)
	return dash
).call()

static func try_next(state : PlayerState):
	var dhis = state.input_history.dir_history
	var lbt = state.input_history.last_bts()
	var lnm = state.input_history.history[0].name(false)
	if move_fwd.cmd.check(dhis, lbt, lnm):
		return new(true)
	elif move_rev.cmd.check(dhis, lbt, lnm):
		return new(false)

func _init(fwd):
	self.fwd = fwd
	anim_name = "66" if fwd else "44"
	move = move_fwd if fwd else move_rev

func init():
	pass

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		return CsIdle.new()

func deinit():
	pass

func step(state : PlayerState):
    _step()
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

