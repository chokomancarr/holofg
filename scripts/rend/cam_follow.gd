extends Node

@onready var par = get_parent() as Camera3D
@onready var pos0 = par.position
@onready var basis0 = par.basis

func _physics_process(_dt):
	var gst = GameMaster.game_state
	if gst:
		if gst.state == GameState.MATCH_STATE.CINEMATIC:
			var inst = CharaRend.insts
			var anchor = CharaRend.insts[int(gst.cinematic_info.is_p2)].cam_anchor
			#par.position = anchor.global_position
			#par.basis = anchor.global_basis
		else:
			var w = gst.wall
			par.position = pos0 + Vector3.RIGHT * ((w.x + w.y) * 0.5 - 5000) * 0.002
			par.basis = basis0
	else:
		par.position.x = 0.0
