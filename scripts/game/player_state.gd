class_name PlayerState

var _info: DT.CharaInfo

var input_history : IN.InputHistory

var bar_health: int
var bar_super: int
var pos: Vector2i
var pos_is_p2: bool
var action_is_p2: bool

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

func prestep() -> PlayerState:
	var tar_state = state
	while tar_state:
		state = tar_state
		tar_state = state.check_next(self)
	return self

#static func from(src: PlayerState) -> PlayerState:
#	var res = ObjUtil.clone(src, new())
#	res.input_history = src.input_history.clone()
#	var tar_state = src.state
#	while tar_state:
#		res.state = tar_state
#		tar_state = res.state.check_next(res)
#	res.state = res.state.clone_next()
#	return res
