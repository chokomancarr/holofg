class_name CharaExpress extends Node

@onready var par = get_parent() as MeshInstance3D

enum KEYS {
	idle, idle_blink, att_1, hurt_1
}
var _keymap = []
func keyvals():
	return [ 0, 0, 0, 0 ]

@onready var el = par.find_blend_shape_by_name("eye_left")
@onready var er = par.find_blend_shape_by_name("eye_right")

var p2 = null:
	set(v):
		p2 = v
		par.set_blend_shape_value(el, 1 if v else 0)
		par.set_blend_shape_value(er, 0 if v else 1)

var expr = EXPR.IDLE

var blink_t = 0
var next_blink_t = 5.0

func _ready():
	_keymap = KEYS.keys().map(func (k): return par.find_blend_shape_by_name(k))

func _process(dt):
	var res = keyvals()
	match expr:
		EXPR.IDLE:
			var bn = 0.0
			blink_t += dt
			if blink_t > next_blink_t:
				blink_t = -0.3
			elif blink_t < -0.15:
				bn = (blink_t + 0.3) / 0.15
			elif blink_t < 0:
				bn = 1.0 - (blink_t + 0.15) / 0.15
			
			res[KEYS.idle] = 1.0 - bn
			res[KEYS.idle_blink] = bn
		EXPR.ATTACK:
			res[KEYS.att_1] = 1.0
		EXPR.STUN:
			res[KEYS.hurt_1] = 1.0
		_:
			pass
	
	for i in range(res.size()):
		par.set_blend_shape_value(_keymap[i], res[i])

enum EXPR {
	IDLE, ATTACK, BLOCK, STUN, CINEMATIC
}
