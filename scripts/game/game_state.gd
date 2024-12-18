class_name GameState

var state: MATCH_STATE

var p1: PlayerState
var p2: PlayerState
var freeze_t: int = 0
var freeze_n: int = 0
var freeze_canbuffer := 0
var cinematic_info: MoveInfo.Cinema
var cinematic_is_p2: bool
var cinematic_t: int = 0
var countdown: int = -1#99 * 60 + 59
var wall = Vector2i(0, 10000)
var hit_uid_counter := 0

func clone():
	return ObjUtil.clone(self, new(),
		[ "state", "freeze_t", "freeze_n", "freeze_canbuffer", "cinematic_is_p2", "cinematic_t", "countdown", "wall", "hit_uid_counter" ],
		[ "p1", "p2" ]
	)

static func from_players(p1, p2):
	var res = new()
	res.p1 = p1
	p1.is_p2 = false
	res.p2 = p2
	p2.is_p2 = true
	return res

func start_intro():
	state = MATCH_STATE.INTRO
	countdown = 200

func start_game_inf():
	state = MATCH_STATE.PREGAME
	countdown = 1

static func from_info(info_p1 : DT.CharaInfo, info_p2 : DT.CharaInfo):
	return from_players(
		PlayerState.create(info_p1, true),
		PlayerState.create(info_p2, false)
	)

func freeze(n, canbuf = 3):
	freeze_t = 0
	freeze_n = n
	freeze_canbuffer = canbuf
	state = MATCH_STATE.ATT_FREEZE

func cinematic(info, p2):
	cinematic_info = info
	cinematic_is_p2 = p2
	cinematic_t = 0
	state = MATCH_STATE.CINEMATIC

func _get_debug_text():
	var pr = func (p : PlayerState, i):
		return "(%s) %s (%s)  P%d" % [p.state.state_t, p.state._STATE_NAME, p.state.anim_name, i]
	
	return "%s\n%s\n%d :state_hash" % [ pr.call(p1, 1), pr.call(p2, 2), dict4hash().hash() ]

func get_anim_timescale():
	return (1.0 / (freeze_n - 1)) if freeze_n > 0 else 1.0

func get_anim_framediff(pi, df = 0.0):
	if state == MATCH_STATE.ATT_FREEZE:
		var excl = (freeze_canbuffer & pi) > 0
		return ((freeze_t + df) / freeze_n) if excl else 1.0
	else:
		return df

func dict4hash():
	return [
		p1.dict4hash(),
		p2.dict4hash(),
		state,
		freeze_t,
		freeze_n,
		freeze_canbuffer,
		cinematic_info,
		cinematic_is_p2,
		cinematic_t,
		countdown,
		wall,
		hit_uid_counter
	]


enum MATCH_STATE {
	INTRO = 0x0000, PREGAME = 0x1001, GAME = 0x2001,
	ATT_FREEZE = 0x3001, CINEMATIC = 0x4001,
	OVER = 0x5000, POST_GAME = 0x6000,
	
	_READ_INPUT_FLAG = 0x01
}
