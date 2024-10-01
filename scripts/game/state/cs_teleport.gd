class_name CsTeleport extends _CsNeutralBase

const NF_TP = 8
const NF_FWD = 34
const NF_UP = 40
const NF_ATT = 18
const TP_DIST = 2000
const TP_MIN_DIST = 300
const TP_BEHIND_FROM = 500

const _STATE_NAME = "teleport"
const COST = 500

const TP_HEIGHT = 170 * 9  #sum (0 + 10 + 20 + ... + 170)
static var _tp9_offset = (func ():
	var _jumpcurve = []
	var _v = 0
	const _g = 10
	for i in range(18):
		_jumpcurve.push_back([0, -_v])
		_v += _g
	_jumpcurve.append_array([ [0, 0], [0, 0], [0, 0] ])
	return DT.OffsetInfo.from_vals(_jumpcurve, 21)
).call()

static var cmd_fwd : IN.InputCommand = (func ():
	var cmd = IN.InputCommand.from_string("66")
	cmd.t_dirs = 10
	cmd.bt = IN.BT.ANY
	return cmd
	).call()

static var cmd_up : IN.InputCommand = (func ():
	var cmd = IN.InputCommand.from_string("88")
	cmd.t_dirs = 10
	cmd.bt = IN.BT.ANY
	return cmd
	).call()

var fwd : bool

func clone():
	return ObjUtil.clone(self, _clone(new(fwd)),
		[ "fwd" ],
		[]
	)

static func try_next(state : PlayerState):
	if state.bar_super > 0:
		if cmd_fwd.check(state.input_history.his[0], state.input_history.dirs):
			state.bar_super -= COST
			return new(true)
		elif cmd_up.check(state.input_history.his[0], state.input_history.dirs):
			state.bar_super -= COST
			return new(false)

func _init(fwd):
	self.fwd = fwd
	anim_name = "tp_startup"

func check_next(state : PlayerState):
	if state_t == NF_TP - 1:
		req_freeze = 5
		state_t += 1
	else:
		if fwd:
			if state_t == NF_FWD:
				return CsIdle.new()
			elif state_t >= NF_ATT:
				return check_actions(state, NF_ATT if state_t == NF_ATT else 1, true)
		else:
			if state_t == NF_UP:
				#return CsLandRecovery.new(3)
				return CsIdle.new()
			elif state_t >= NF_ATT:
				var next = CsAirNormal.try_next(state, 6, ST.CancelInfo.from_all(), 9)
				if next:
					next.jump_traj = _tp9_offset
					next.jump_traj_off = state_t - NF_TP - 2
					return next

func step(state : PlayerState):
	_step()
	if state_t == NF_TP + 1:
		use_pos_flip = true
		var do = absi(state.dist_to_opp.x)
		if do < TP_BEHIND_FROM:
			next_offset.x = do + TP_MIN_DIST
		else:
			next_offset.x = mini(TP_DIST, do - TP_MIN_DIST)
		if not fwd:
			next_offset.y = TP_HEIGHT
		anim_name = "tp_6" if fwd else "tp_9"
	elif state_t > NF_TP + 1:
		next_offset = _tp9_offset.eval(state_t - NF_TP - 2)
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

func get_anim_frame(df):
	return state_t - 5 if state_t > NF_TP else state_t - 1

func get_frame_meter_color():
	return Color.GREEN_YELLOW

func dict4hash():
	return [ _STATE_NAME,
		
	]
