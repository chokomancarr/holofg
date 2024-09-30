extends Node

@onready var par = get_parent() as Camera3D

func _physics_process(_dt):
	var gst = GameMaster.game_state
	if gst:
		if gst.state == GameMaster.MATCH_STATE.CINEMATIC:
			var anchor = CharaRend.insts[int(gst.cinematic_info.is_p2)]
			par.position = anchor.global_position
			par.basis = anchor.global_basis
		else:
			var w = gst.wall
			par.position.x = ((w.x + w.y) * 0.5 - 5000) * 0.002
	else:
		par.position.x = 0.0
