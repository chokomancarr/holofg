class_name CharaPalette extends Node

static var palette_all = {}
static var palette = [ null, null ]

static func load_palette(i):
	if not palette_all.has(i):
		var json = (load("res://database/chara_palette_%d.json" % i) as JSON).data
		palette_all[i] = {
			"costume1": json.costume_1.map(func (cc): 
				return cc.map(func (c): return Color.from_string("#" + c, Color.BLACK))
				)
		}

func apply_palette(p):
	var m = ($"../towa_8/Armature/Skeleton3D/clothes_a" as MeshInstance3D)
	var mat = m.material_override.duplicate(true) as ShaderMaterial
	
	if not palette[p]:
		load_palette(2)
		palette[p] = palette_all[2].costume1[0]
	
	var pl = palette[p]
	
	for i in range(6):
		mat.set_shader_parameter("palette%d" % (i + 1), pl[i])

	m.material_override = mat
	m = ($"../towa_8/Armature/Skeleton3D/clothes_b" as MeshInstance3D)
	m.material_override = mat
	m = ($"../towa_8/Armature/Skeleton3D/hat" as MeshInstance3D)
	m.material_override = mat
	m = ($"../towa_8/Armature/Skeleton3D/hair" as MeshInstance3D)
	m.material_override = mat
