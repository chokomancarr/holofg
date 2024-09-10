extends Node

@onready var par = get_parent() as Camera3D

func _physics_process(_dt):
	if GameMaster.game_state:
		var w = GameMaster.game_state.wall
		par.position.x = ((w.x + w.y) * 0.5 - 5000) * 0.002
	else:
		par.position.x = 0.0
