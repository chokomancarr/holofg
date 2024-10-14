extends Control

@export var kill = true

func _ready():
	visible = true

func reset():
	modulate.a = 1.0

func _process(dt):
	modulate.a -= dt
	if modulate.a <= 0:
		if kill:
			queue_free()
