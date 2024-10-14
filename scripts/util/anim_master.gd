class_name ANIM

class AnimLib:
	var me : AnimationLibrary
	var me_flip : AnimationLibrary
	var opp : AnimationLibrary
	var opp_flip : AnimationLibrary
	
	func _init():
		me = AnimationLibrary.new()
		me_flip = AnimationLibrary.new()
		opp = AnimationLibrary.new()
		opp_flip = AnimationLibrary.new()

static func register(chara_id : int, par : AnimationPlayer):
	var lib = GameMaster.anim_lib.get(chara_id)
	if not lib:
		lib = reg_lib(chara_id, par)
	
	par.add_animation_library("me", lib.me)
	par.add_animation_library("me_flipped", lib.me_flip)

static func post_register(opp_id : int, par : AnimationPlayer):
	var lib = GameMaster.anim_lib.get(opp_id)
	assert(lib, "opponent does not have lib setup yet!")
	
	par.add_animation_library("opp", lib.opp)
	par.add_animation_library("opp_flipped", lib.opp_flip)

static func reg_lib(chara_id, par : AnimationPlayer):
	var res = AnimLib.new()
	
	var path = "res://models/chara/%d/anims" % chara_id
	var dir := DirAccess.open(path)
	for fl in dir.get_files():
		var clp = load(path + "/" + fl)
		if clp is Animation:
			var cnm = fl.trim_suffix(".res")
			if cnm.begins_with("opp_"):
				var to = to_opp(clp, true)
				res.opp_flip.add_animation(cnm, to)
			else:
				var to = to_opp(clp, false)
				res.me.add_animation(cnm, to)
			#print_debug("reg ", chara_id, " clip: ", cnm)
	
	for anm in res.me.get_animation_list():
		var src = res.me.get_animation(anm)
		res.me_flip.add_animation(anm, do_flip(src))
	
	for anm in res.opp_flip.get_animation_list():
		var src = res.opp_flip.get_animation(anm)
		res.opp.add_animation(anm, do_flip(src))
	
	GameMaster.anim_lib[chara_id] = res
	return res

static func do_flip(a : Animation):
	var lib = Animation.new()
	lib.loop_mode = a.loop_mode
	var ntrack = a.get_track_count()
	for t in range(ntrack):
		var ty = a.track_get_type(t)
		var r = lib.add_track(ty)
		var path = a.track_get_path(t)
		if not path:
			continue
		var psnm = path.get_concatenated_subnames()
		if not psnm.contains(".noflip."):
			if psnm.ends_with(".L"):
				#psnm = psnm.rsplit(".L", false, 1)[0] + ".R"
				psnm = psnm.trim_suffix("L") + "R"
			elif psnm.ends_with(".R"):
				#psnm = psnm.rsplit(".R", false, 1)[0] + ".L"
				psnm = psnm.trim_suffix("R") + "L"
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
	return lib

static func to_opp(a : Animation, opp):
	var lib = Animation.new()
	for t in range(a.get_track_count()):
		var ty = a.track_get_type(t)
		var path = a.track_get_path(t)
		
		var path2 = path.get_concatenated_names()
		if opp != path2.begins_with("opp_"):
			continue
		if opp:
			path2 = path2.trim_prefix("opp_")
		
		var psnm = path.get_concatenated_subnames().trim_suffix("_2")
		
		var r = lib.add_track(a.track_get_type(t))
		lib.track_set_path(r, NodePath(path2 + ":" + psnm))
		lib.length = a.length
		for i in range(a.track_get_key_count(t)):
			if ty == Animation.TYPE_POSITION_3D:
				lib.track_insert_key(r,
					a.track_get_key_time(t, i),
					a.track_get_key_value(t, i),
					a.track_get_key_transition(t, i)
				)
			else:
				lib.track_insert_key(r,
					a.track_get_key_time(t, i),
					a.track_get_key_value(t, i),
					a.track_get_key_transition(t, i)
				)
	return lib
