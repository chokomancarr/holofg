class_name PlayerState

var _info: DT.CharaInfo

var input_history : IN.InputHistory

var bar_health: int
var bar_super: int
var pos: Vector2i
var bounded_pos: Vector2i
var pos_is_p2: bool
var action_is_p2: bool

var dist_to_opp: Vector2i

var summons: _SmBase

var boxes: Array[ST.BoxInfo] = []

var state: _CsBase

static func create(info : DT.CharaInfo, is_p1 : bool) -> PlayerState:
	var res = new()
	res._info = info
	res.bar_health = info.max_health
	res.input_history = IN.InputHistory.new()
	res.pos = Vector2i(4000 if is_p1 else 6000, 0)
	res.pos_is_p2 = !is_p1
	res.action_is_p2 = !is_p1
	res.state = CsIdle.new()
	return res

func add_inputs(inputs : IN.InputState) -> PlayerState:
	if pos_is_p2:
		inputs.val |= IN.DIR_FLIP_BIT
	else:
		inputs.val &= ~IN.DIR_FLIP_BIT
	input_history.push(inputs)
	return self

func prestep():
	var n = 0
	var tar_state = state.check_next(self)
	if state.use_pos_flip:
		action_is_p2 = pos_is_p2
	while tar_state:
		n += 1
		assert(n < 7, "transition limit per frame reached! there might be infinite loops?")
		state.deinit(self)
		state = tar_state
		state.init(self)
		if state.use_pos_flip:
			action_is_p2 = pos_is_p2
		tar_state = state.check_next(self)

func step():
	state.step(self)
	if action_is_p2:
		state.next_offset.x *= -1
	pos += state.next_offset
	bounded_pos = pos + (state.bounds_off if action_is_p2 else -state.bounds_off)

func dict4hash():
	return [
		input_history.dict4hash(),
		bar_health,
		bar_super,
		pos,
		bounded_pos,
		pos_is_p2,
		action_is_p2,
		dist_to_opp,
		#summons,
		boxes.map(func (b : ST.BoxInfo): return b.hashed()),
		state._dict4hash()
	]
