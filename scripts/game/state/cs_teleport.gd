class_name CsTeleport extends _CsNeutralBase

const NF_FWD = 34
const NF_ATT = 20
const TP_DIST = 2000
const TP_MIN_DIST = 300
const TP_BEHIND_FROM = 500

const _STATE_NAME = "teleport"

static var cmd_fwd : IN.InputCommand = (func ():
	var cmd = IN.InputCommand.from_string("66")
	cmd.t_dirs = 10
	cmd.bt = IN.BT.ANY
	return cmd
	).call()

var fwd : bool

static func try_next(state : PlayerState):
	if cmd_fwd.check(state.input_history):
		return new(true)

func _init(fwd):
	self.fwd = fwd
	anim_name = "tp_startup"

func check_next(state : PlayerState):
	if state_t == NF_FWD:
		return CsIdle.new()
	elif state_t >= NF_ATT:
		return check_actions(state, NF_ATT if state_t == NF_ATT else 1, true)

func step(state : PlayerState):
	_step()
	if state_t == 4:
		req_freeze = 5
	elif state_t == 5:
		use_pos_flip = true
		var do = absi(state.dist_to_opp.x)
		if do < TP_BEHIND_FROM:
			next_offset.x = do + TP_MIN_DIST
		else:
			next_offset.x = mini(TP_DIST, do - TP_MIN_DIST)
		anim_name = "tp_6" if fwd else "tp_9"
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

func get_anim_frame(df):
	return state_t - 5 if state_t > 4 else state_t - 1

func get_frame_meter_color():
	return Color.GREEN_YELLOW
