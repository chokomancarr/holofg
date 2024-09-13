class_name GameState

var p1: PlayerState
var p2: PlayerState
var freeze_t: int = 0
var freeze_n: int = 0
var freeze_canbuffer := false
var countdown: int = -1#99 * 60 + 59
var wall = Vector2i(0, 10000)

static func from_players(p1, p2):
	var res = new()
	res.p1 = p1
	res.p2 = p2
	return res

static func from_info(info_p1 : DT.CharaInfo, info_p2 : DT.CharaInfo):
	return from_players(
		PlayerState.create(info_p1, true),
		PlayerState.create(info_p2, false)
	)

func is_frozen():
	return freeze_n > 0

func freeze(n, canbuf = false):
	freeze_t = 0
	freeze_n = n
	freeze_canbuffer = canbuf

func _get_debug_text():
	var pr = func (p : PlayerState, i):
		return "(%s) %s (%s)  P%d" % [p.state.state_t, p.state._STATE_NAME, p.state.anim_name, i]
	
	return "%s\n%s" % [ pr.call(p1, 1), pr.call(p2, 2) ]

func get_anim_timescale():
	return (1.0 / (freeze_n - 1)) if is_frozen() else 1.0

func get_anim_framediff():
	return (freeze_t * 1.0 / freeze_n) if is_frozen() else 0.0
