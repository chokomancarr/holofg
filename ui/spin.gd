extends Control

func _process(dt):
	if is_visible_in_tree():
		rotation_degrees += dt * 360
