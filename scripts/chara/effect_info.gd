class_name EffectInfo

var scene : PackedScene
var t_range = Vector2i(0, 100000)
var anchor = ANCHOR.BASE

class BgFilterInfo:
	var col_near : Color
	var col_far : Color
	var col_sky : Color

static func load_data(path : String):
	var src = (load("res://database/%s.json" % path) as JSON).data as Dictionary
	
	var res = {}
	
	for nm in src:
		var o2 = src[nm] as Array
		
		res[nm] = o2.map(func (o):
			if o.has("bg_filter"):
				var bg = BgFilterInfo.new()
				var c = o.bg_filter
				bg.col_near = Color(c[0])
				bg.col_far = Color(c[1])
				bg.col_sky = Color(c[2])
				return bg
			else:
				var ef = new()
				ef.scene = load("res://chara_scenes/effects/%s.tscn" % o.scene) as PackedScene
				if o.has("t_start"): ef.t_range.x = o.t_start
				if o.has("t_end"): ef.t_range.y = o.t_end
				if o.has("anchor"): ef.anchor = ANCHOR.get(o.anchor)
			
				return ef
		)
	
	return res

enum ANCHOR {
	BASE, HIP, HAND_L, HAND_R, LEG_L, LEG_R
}
