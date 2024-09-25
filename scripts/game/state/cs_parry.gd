class_name CsParry extends _CsBase

const NF_MIN = 10

const _STATE_NAME = "parry"

var in_recovery = false
var do_in_recovery = false
var rec_df : int

var NF_RECOVERY = 30

var parried_nf = -1

func clone():
	return ObjUtil.clone(self, _clone(new(self.state_t + 1)),
		[ "in_recovery", "do_in_recovery", "rec_df", "NF_RECOVERY", "parried_nf" ],
		[]
	)

static func try_next(state : PlayerState):
	var his = state.input_history.his[0]
	if his.bt(IN.BT.p):
		return new(his.nf)

func _init(n):
	self.state_t = n - 1
	anim_name = "parry"

func check_next(state : PlayerState):
	if (in_recovery and state_t >= NF_RECOVERY + rec_df - 1) or state_t == 1000000:
			return CsIdle.new()
	else:
		var next = CsTeleport.try_next(state)
		if next: return next

func step(state : PlayerState):
	_step()
	if parried_nf > 0:
		NF_RECOVERY = 4
		parried_nf -= 1
		if parried_nf == 1 and not state.input_history.his[0].bt(IN.BT.p):
			state_t = 1000000
	else:
		if not in_recovery:
			if not state.input_history.his[0].bt(IN.BT.p):
				in_recovery = true
				rec_df = state_t
				#if parried_nf == 0:
				#	state_t = 1000000
		do_in_recovery = in_recovery and state_t > NF_MIN
		if not do_in_recovery:
			rec_df += 1
		else:
			anim_name = "parry_recovery"
	state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

func get_anim_frame(df):
	if do_in_recovery:
		return ((state_t - rec_df) * 60.0) / NF_RECOVERY
	else:
		return -1

func get_frame_meter_color():
	return Color.ROYAL_BLUE if do_in_recovery else Color.HOT_PINK if parried_nf > 0 else Color.LIGHT_PINK

func query_stun():
	return ST.STUN_TY.PUNISH_COUNTER if do_in_recovery else ST.STUN_TY.PARRY

func dict4hash():
	return [ _STATE_NAME,
		in_recovery,
		do_in_recovery,
		rec_df,
		NF_RECOVERY,
		parried_nf
	]
