class_name PlayerState

var _info: DT.CharaInfo

var input_history : IN.InputHistory

var bar_health: int
var bar_super: int
var pos: Vector2i
var pos_is_p2: bool
var action_is_p2: bool

var dist_to_opp: Vector2i

var summons: _SmBase

var boxes: Array[ST.BoxInfo] = []
var move_name: String = "5"

var state: _CsBase

static func create(info : DT.CharaInfo, is_p1 : bool) -> PlayerState:
	var res = new()
	res._info = info
	res.bar_health = info.max_health
	#res.input_history = [ IN.InputState.new() ] as Array[IN.InputState]
	res.input_history = IN.InputHistory.new()
	res.pos = Vector2i(4000 if is_p1 else 6000, 0)
	res.pos_is_p2 = !is_p1
	res.action_is_p2 = !is_p1
	res.state = CsIdle.new()
	return res

func add_inputs(inputs : IN.InputState) -> PlayerState:
	if action_is_p2:
		inputs.val |= IN.DIR_FLIP_BIT
	else:
		inputs.val &= ~IN.DIR_FLIP_BIT
	input_history.push(inputs)
	return self

func prestep():
	var n = 0
	var tar_state = state
	while tar_state:
		n += 1
		if n > 1:
			print_debug(state._STATE_NAME, " -> ", tar_state._STATE_NAME)
		state = tar_state
		if state.use_pos_flip:
			action_is_p2 = pos_is_p2
		tar_state = state.check_next(self)

func step():
	state.step(self)
	pos += state.next_offset

func on_hit(hit_info, dist):
	state = CsStun.new(self, hit_info)
