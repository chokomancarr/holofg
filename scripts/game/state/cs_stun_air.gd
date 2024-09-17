class_name CsStunAir extends _CsBase

const _STATE_NAME = "stun_air"

var vel : Vector2i
var ty : ST.STUN_AIR_TY

const _G = 10

func _init(p : PlayerState, ty : ST.STUN_AIR_TY):
	state_t = 1
	self.ty = ty
	match ty:
		ST.STUN_AIR_TY.RESET:
			anim_name = "stun_air_reset"
			vel = Vector2i(-10, 120)
		ST.STUN_AIR_TY.JUGGLE:
			anim_name = "stun_air_juggle"
			vel = Vector2i(-20, 150)
	
func check_next(state : PlayerState):
	if state.pos.y == 0 and vel.y < 0:
		match ty:
			ST.STUN_AIR_TY.RESET:
				return CsIdle.new()
			ST.STUN_AIR_TY.JUGGLE:
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

func get_anim_frame(df):
	if state_t == 1:
		return df
	else:
		return -1

func get_frame_meter_color():
	return Color.YELLOW

func dict4hash():
	return [ _STATE_NAME,
		vel, ty
	]
