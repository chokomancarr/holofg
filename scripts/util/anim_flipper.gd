extends Node

@onready var par : AnimationPlayer = get_parent()

func _ready():
	var src = par.get_animation_library("")
	var tar = AnimationLibrary.new()
	
	for anm in src.get_animation_list():
		var lib = Animation.new()
		var a : Animation = src.get_animation(anm)
		for t in range(a.get_track_count()):
			var ty = a.track_get_type(t)
			var r = lib.add_track(ty)
			var path = a.track_get_path(t)
			var psnm = path.get_concatenated_subnames()
			if not psnm.contains(".noflip."):
				if psnm.ends_with(".L"):
					psnm = psnm.rsplit(".L", false, 1)[0] + ".R"
				elif psnm.ends_with(".R"):
					psnm = psnm.rsplit(".R", false, 1)[0] + ".L"
			lib.track_set_path(r, NodePath(path.get_concatenated_names() + ":" + psnm))
			lib.length = a.length
			for i in range(a.track_get_key_count(t)):
				match ty:
					Animation.TYPE_POSITION_3D:
						lib.track_insert_key(r,
							a.track_get_key_time(t, i),
							a.track_get_key_value(t, i) * Vector3(-1, 1, 1),
							a.track_get_key_transition(t, i)
						)
					Animation.TYPE_ROTATION_3D:
						var qt = a.track_get_key_value(t, i) as Quaternion
						lib.track_insert_key(r,
							a.track_get_key_time(t, i),
							Quaternion(qt.x, -qt.y, -qt.z, qt.w),
							a.track_get_key_transition(t, i)
						)
					Animation.TYPE_SCALE_3D:
						lib.track_insert_key(r,
							a.track_get_key_time(t, i),
							a.track_get_key_value(t, i),
							a.track_get_key_transition(t, i)
						)
					_:
						pass
		tar.add_animation(anm, lib)
	par.add_animation_library("flipped", tar)
