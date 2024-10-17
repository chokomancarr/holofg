class_name CharaAnimPlayer extends Node

@onready var anim = get_parent() as AnimationPlayer

const FRAME2TIME = 1.0 / 60 #animations are imported as 60fps

var last_phy_t : float = 0

var missing_anims = []

func _physics_process(_dt):
	last_phy_t = 0

func _process(dt):
	last_phy_t = minf(last_phy_t + dt, 1.0 / Engine.physics_ticks_per_second)

func _ready():
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func step(gst : GameState, pst : PlayerState, delta):
	match gst.state:
		GameState.MATCH_STATE.INTRO:
			if pst.is_p2 == (gst.countdown <= 100):
				var dframe = last_phy_t * Engine.physics_ticks_per_second
				var gt = gst.countdown
				if gt > 100:
					gt -= 100
				var t = (100 - gt) + dframe
				var lib_name = "me_flipped/" if pst.action_is_p2 else "me/"
				anim.play(lib_name + "walk_in_1")
				anim.seek(t * FRAME2TIME, true)
		_:
			var dframe = last_phy_t * Engine.physics_ticks_per_second
			
			if gst.state == GameState.MATCH_STATE.PREGAME and gst.countdown > (200 - 80):
				var gt = gst.countdown
				var t = (200 - gt) + dframe
				var lib_name = "me_flipped/" if pst.action_is_p2 else "me/"
				anim.play(lib_name + "pregame_1")
				anim.seek(t * FRAME2TIME, true)
			else:
				var anim_name = pst.state.anim_name
				var lib_name = "me_flipped/" if pst.action_is_p2 else "me/"
				var spl = anim_name.split("/")
				if spl.size() > 1:
					anim_name = spl[1]
					lib_name = spl[0] + "_flipped/" if pst.action_is_p2 else spl[0] + "/"
				anim_name = lib_name + anim_name
				var frame = pst.state.get_anim_frame(gst.get_anim_framediff(2 if pst.is_p2 else 1, dframe))
				if not anim.has_animation(anim_name):
					if not missing_anims.has(anim_name):
						missing_anims.push_back(anim_name)
						print_debug("missing animation clip for ", anim_name)
					return
				anim.play(anim_name)
				if frame >= 0:
					anim.seek(frame * FRAME2TIME, true)
				else:
					anim.advance(delta * gst.get_anim_timescale() * Engine.physics_ticks_per_second / 60.0)

func step_cinematic(anim_name : String, pst : PlayerState, t : int):
	var lib_name = "me_flipped/" if pst.action_is_p2 else "me/"
	var spl = anim_name.split("/")
	if spl.size() > 1:
		anim_name = spl[1]
		lib_name = spl[0] + "_flipped/" if pst.action_is_p2 else spl[0] + "/"
	anim_name = lib_name + anim_name
	if not anim.has_animation(anim_name):
		if not missing_anims.has(anim_name):
			missing_anims.push_back(anim_name)
			print_debug("missing animation clip for ", anim_name)
		return
	anim.play(anim_name)
	anim.seek(t * FRAME2TIME, true)
