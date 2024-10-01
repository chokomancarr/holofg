class_name PlayerState

var _info: DT.CharaInfo

var input_history : IN.InputHistory

var bar_health: int:
	set(v):
		bar_health = mini(maxi(v, 0), _info.max_health)
var bar_super: int:
	set(v):
		bar_super = mini(maxi(v, 0), 3000)

var pos: Vector2i
var bounded_pos: Vector2i
var dist_to_opp: Vector2i

var is_p2: bool
var pos_is_p2: bool
var action_is_p2: bool
var flip_next: bool

var can_super: bool #if the other player used super, dont super at the same frame

var summons: Array[SummonState]
var summon_uid : int

var boxes: Array[ST.BoxInfo] = []

var state: _CsBase

func clone() -> PlayerState:
	return ObjUtil.clone(self, new(),
		[ "_info", "bar_health", "bar_super", "pos", "bounded_pos", "dist_to_opp",
			"is_p2", "pos_is_p2", "action_is_p2", "summon_uid" ],
		[ "input_history", "state" ],
		func (a, b):
			b.summons.assign(a.summons.map(func (s): return s.clone()))
			b.boxes = a.boxes.duplicate()
	)

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
	state.req_freeze = 0
	state.req_cinematic = null
	flip_next = state.use_pos_flip
	var tar_state = state.check_next(self)
	while tar_state:
		n += 1
		assert(n < 7, "transition limit per frame reached! there might be infinite loops?")
		state.deinit(self)
		state = tar_state
		state.init(self)
		flip_next = flip_next or state.use_pos_flip
		tar_state = state.check_next(self)
	
	summons = summons.filter(func (s : SummonState): return not s.last_tick)

func step():
	state.step(self)
	if action_is_p2:
		state.next_offset.x *= -1
	pos += state.next_offset
	bounded_pos = pos + (state.bounds_off if action_is_p2 else -state.bounds_off)
	
	for s in summons:
		s.step()
		if s.is_p2:
			s.next_offset.x *= -1
		s.pos += s.next_offset

func dict4hash():
	return [
		input_history.dict4hash(),
		bar_health,
		bar_super,
		pos,
		bounded_pos,
		dist_to_opp,
		is_p2,
		pos_is_p2,
		action_is_p2,
		summons.map(func (s): return s.dict4hash()),
		summon_uid,
		boxes.map(func (b : ST.BoxInfo): return b.hashed()),
		state._dict4hash()
	]
