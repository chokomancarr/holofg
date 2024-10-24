class_name EffectRend

static var effect_data_common = null
static var effect_data = {}

static var hit_sparks = null

var bg_filter : MeshInstance3D
var bg_filter_mat : ShaderMaterial

var info : Dictionary
var chara_rend : CharaRend
var effects : Array[EffCtrl]
var effects_all : Array
var last_eff = null
var eff_is_recovery = false

func _init(chara_id, chara_rend : CharaRend):
	self.chara_rend = chara_rend
	if not effect_data_common:
		effect_data_common = EffectInfo.load_data("common_effects")
		hit_sparks = [
			preload("res://chara_scenes/effects/hit_flash.tscn") as PackedScene
		]
	if not effect_data.has(chara_id):
		effect_data[chara_id] = EffectInfo.load_data("chara_effects_%d" % chara_id)
	
	info = effect_data[chara_id]
	
	_reg_objs.call_deferred()

func _reg_objs():
	bg_filter = chara_rend.get_node("/root/main/%bg_filter" + str(1 if chara_rend.is_p1 else 2))
	bg_filter_mat = bg_filter.material_override

func process(pst : PlayerState, cine):
	if pst.state is _CsStunBase:
		if pst.state.eff_pos != Vector2i.ZERO:
			var sp = hit_sparks[0].instantiate() as EffCtrl
			chara_rend.add_child(sp)
			sp.global_position = Vector3(
				(pst.state.eff_pos.x - 5000) * 0.002,
				pst.state.eff_pos.y * 0.002,
				0
			)
			sp.global_rotation = Vector3.ZERO
			sp.pi = 2 if pst.is_p2 else 1
			if pst.action_is_p2:
				sp.scale.x *= -1
			effects = [
				sp
			]
			effects_all = []
			pst.state.eff_pos = Vector2i.ZERO
		last_eff = "_stun_"
	else:
		var nm = pst.state.anim_name
		if cine:
			nm += "_cine"
		if last_eff != nm:
			if not nm.ends_with("_recovery"):
				for e in effects:
					if e: e.queue_free()
				bg_filter.visible = false
				effects = []
				effects_all = []
				if info.has(nm):
					_get_eff(info[nm])
				elif effect_data_common.has(nm):
					_get_eff(effect_data_common[nm])
				last_eff = nm
				eff_is_recovery = false
			else:
				eff_is_recovery = true
	
	for i in range(effects_all.size()):
		var e = effects_all[i]
		if e is EffectInfo:
			if e.t_range.x <= pst.state.state_t and e.t_range.y > pst.state.state_t:
				if not effects[i]:
					var scn = e.scene.instantiate() as EffCtrl
					scn.pi = 2 if pst.is_p2 else 1
					chara_rend.anchors[e.anchor].add_child(scn)
					effects[i] = scn
			elif effects[i]:
				effects[i].queue_free()
			
			if effects[i]:
				effects[i].in_recovery = eff_is_recovery

func _get_eff(arr : Array):
	effects.resize(arr.size())
	effects_all = arr
	
	for a in arr:
		if a is EffectInfo.BgFilterInfo:
			bg_filter.visible = true
			bg_filter_mat.set_shader_parameter("col_near", a.col_near)
			bg_filter_mat.set_shader_parameter("col_far", a.col_far)
			bg_filter_mat.set_shader_parameter("col_sky", a.col_sky)
