class_name CharaAnimPlayer extends Node

@onready var anim = get_parent() as AnimationPlayer

const FRAME2TIME = 1.0 / 60 #animations are imported as 60fps

func _ready():
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func step(gst : GameState, pst : PlayerState, delta):
	var anim_name = pst.state.anim_name
	var frame = pst.state.get_anim_frame()
	if pst.action_is_p2:
		anim_name = "flipped/" + anim_name
	if not anim.has_animation(anim_name):
		return
	anim.play(anim_name)
	if frame >= 0:
		anim.seek((frame + gst.get_anim_framediff()) * FRAME2TIME, true)
	else:
		anim.advance(delta * gst.get_anim_timescale() * Engine.physics_ticks_per_second / 60.0)
