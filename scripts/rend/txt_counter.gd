class_name TxtCounter extends Node3D

var uid : int
@onready var lbl = $"Label3D" as Label3D
var psign = 1

func init(pst : PlayerState, cr : CharaRend):
	if not pst.action_is_p2:
		psign = -1

func _ready():
	if psign < 0:
		lbl.text_direction = TextServer.DIRECTION_RTL
		lbl.position.x *= -1

var _t = 1.0

func _process(dt):
	lbl.position.x += 0.2 * dt * psign
	lbl.line_spacing += 10 * dt
	_t -= dt
	if _t < 0:
		queue_free()
	elif _t < 0.2:
		lbl.modulate.a = _t * 5
