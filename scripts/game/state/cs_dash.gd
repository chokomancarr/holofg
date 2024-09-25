class_name CsDash extends _CsBase

const _STATE_NAME = "dash"

var fwd = true
var move : DT.MoveInfo

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "fwd, move" ],
		[]
	)

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
	dash.name = "44"
	dash.cmd = IN.InputCommand.from_string("44")
	dash.cmd.t_dirs = 10
	dash.n_frames = 20
	dash.offsets = DT.OffsetInfo.from_keys([ [0, Vector2i(-40, 0)], [10, Vector2i(-20, 0)] ], 20)
	return dash
).call()

static func try_next(state : PlayerState):
	if state.input_history.his[0].nf > 1:
		return null
	
	if move_fwd.cmd.check(state.input_history):
		return new(true)
	elif move_rev.cmd.check(state.input_history):
		return new(false)

func _init(fwd):
	self.fwd = fwd
	anim_name = "66" if fwd else "44"
	move = move_fwd if fwd else move_rev

func check_next(state : PlayerState):
	if state_t == move.n_frames:
		return CsIdle.new()

func step(state : PlayerState):
	_step()
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]
	next_offset = move.offsets.eval(state_t - 1)

func get_frame_meter_color():
	return Color.LIGHT_BLUE

func dict4hash():
	return [ _STATE_NAME,
		fwd
	]
