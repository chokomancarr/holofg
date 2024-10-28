class_name CsStunAir extends _CsStunBase

const _STATE_NAME = "stun_air"

var vel : Vector2i
var ty : ST.STUN_AIR_TY

const _G = 10

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ "vel", "ty" ],
		[]
	)

func _init(p : PlayerState = null, ty : ST.STUN_AIR_TY = ST.STUN_AIR_TY.RESET, v = null):
	if p:
		state_t = 1 
		airborne = true
		if p.pos.y == 0:
			p.pos.y = 1
		self.ty = ty
		match ty:
			ST.STUN_AIR_TY.RESET:
				anim_name = "stun_air_reset"
				vel = v if v else Vector2i(-10, 120)
			ST.STUN_AIR_TY.JUGGLE:
				anim_name = "stun_air_juggle"
				vel = v if v else Vector2i(-20, 150)
			ST.STUN_AIR_TY.LIM_JUGGLE:
				anim_name = "stun_air_limjuggle"
				vel = v if v else Vector2i(-20, 150)
	
func check_next(state : PlayerState):
	if state.pos.y == 0 and vel.y < 0:
		match ty:
			ST.STUN_AIR_TY.RESET:
				return CsIdle.new()
			_:
				return CsKnockRecover.new()

func step(state : PlayerState):
	_step()
	next_offset = vel
	vel.y -= _G
	
	match ty:
		ST.STUN_AIR_TY.RESET:
			state.boxes = []
		ST.STUN_AIR_TY.JUGGLE:
			state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]
		ST.STUN_AIR_TY.LIM_JUGGLE:
			state.boxes = [state._info.idle_box] as Array[ST.BoxInfo]

func get_anim_frame(df):
	if state_t == 1:
		return df
	else:
		return -1

func get_frame_meter_color():
	return Color.YELLOW

func dict4hash2():
	return [ _STATE_NAME,
		vel, ty
	]
