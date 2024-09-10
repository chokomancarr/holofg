class_name CharaAnimPlayer extends Node

@onready var anim = get_parent() as AnimationPlayer

const FRAME2TIME = 1.0 / 60 #animations are imported as 60fps

func _ready():
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func step(pst : PlayerState, delta):
	var anim_name = pst.state.anim_name
	var frame = pst.state.get_anim_frame()
	if pst.action_is_p2:
		anim_name = "flipped/" + anim_name
	if not anim.has_animation(anim_name):
		return
	anim.play(anim_name)
	if frame >= 0:
		anim.seek(frame * FRAME2TIME, true)
	else:
		anim.advance(delta)
	#match pst.state:
		#ST.STATE_TY.ACTION:
			#var dt = 0.0 if GameMaster.game_state.is_frozen() else GameMaster.get_state_diff_frame()
			#play_anim(pst.move_name, FRAME2TIME, pst.action_is_p2, pst.state_t + dt)
		#ST.STATE_TY.STUN:
			#var t = 0
			#var dt = 0
			#if pst.state_t == 0:
				#t = FRAME2TIME + GameMaster.game_state.freeze_t * FRAME2TIME / GameMaster.game_state.freeze_n
				#dt = FRAME2TIME / GameMaster.game_state.freeze_n
			#else:
				#t = pst.state_t * 1.0 / (pst.stun_t - 1)
				#dt = 1.0 / (pst.stun_t - 1)
			#play_anim(pst.move_name, 1.0, pst.action_is_p2, t + dt * GameMaster.get_state_diff_frame())
		#_:
			#play_anim(pst.move_name, delta * Engine.physics_ticks_per_second / 60.0, pst.action_is_p2)

func play_anim(anim_name, dt, is_p2, frame = -1):
	if is_p2:
		anim_name = "flipped/" + anim_name
	if not anim.has_animation(anim_name):
		#print_debug("missing animation: ", anim_name + "!")
		return
	anim.play(anim_name)
	if frame >= 0:
		anim.seek(frame * dt, true)
	else:
		anim.advance(dt)
