class_name CharaStreaks extends Node

class StreakData:
	var bones : Array[String]
	var gradient : Dictionary

static var database = {}
static var mat : ShaderMaterial

var chara_rend : CharaRend
var info : Dictionary
var rends : Dictionary

func _init(chara_id, chara_rend : CharaRend):
	self.chara_rend = chara_rend
	
	if not mat:
		mat = load("res://effects/motion_streaks_mat.tres")
	
	if not database.has(chara_id):
		database[chara_id] = _load_data("res://database/chara_streaks_%d.json" % chara_id)
	
	info = database[chara_id]
	
	_reg_objs.call_deferred()

func _reg_objs():
	var skel = get_node("../Armature/Skeleton3D")
	for k in info:
		var d = info[k] as StreakData
		var nd = AttTrail.new()
		skel.add_child(nd)
		nd.set_chain(d.bones)
		var mt = mat.duplicate() as ShaderMaterial
		var grd = GradientTexture1D.new()
		grd.gradient = Gradient.new()
		for g in d.gradient:
			var v = d.gradient[g]
			if v is String:
				v = Color.from_string("#" + v, Color.BLACK)
			else:
				v = CharaPalette.palette[0 if chara_rend.is_p1 else 1][int(v)-1]
			grd.gradient.add_point(float(g), v)
		
		grd.gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		mt.set_shader_parameter("gradient", grd)
		nd.material_override = mt
		
		rends[k] = nd
		chara_rend.set_rend_layers(nd)

func step(pst : PlayerState, cr : CharaRend):
	for r in rends.values():
		r.generate = false
	var st = pst.state
	if st is _CsAttBase:
		for s in st.move.streaks:
			var fr = s.frame_range
			if st.state_t >= fr.x and st.state_t <= fr.y:
				rends[s.name_flip if pst.action_is_p2 else s.name].generate = true

func _load_data(path):
	var data = (load(path) as JSON).data
	var res = {}
	for d in data:
		var dd = StreakData.new()
		dd.bones.assign(data[d].bones)
		dd.gradient = data[d].gradient
		res[d] = dd
	return res
