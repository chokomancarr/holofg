class_name SummonRend extends Node3D

var state : SummonState

func _ready():
	rotation.y = PI * 0.5 * (-1 if state.is_p2 else 1)

func _process(_dt):
	position.x = (state.pos.x - 5000) * 0.002
	position.y = state.pos.y * 0.002
