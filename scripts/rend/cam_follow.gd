extends Node

@onready var par = get_parent() as Camera3D
@onready var pos0 = par.position
@onready var basis0 = par.basis

@onready var ppl1cam = $"../player1/ppl1cam" as Camera3D
@onready var ppl2cam = $"../player2/ppl2cam" as Camera3D
@onready var ppl12cam = $"../player12/ppl12cam" as Camera3D

func _physics_process(_dt):
	var gst = GameMaster.game_state
	if gst:
		match gst.state:
			GameState.MATCH_STATE.INTRO:
				var anchor = CharaRend.insts[0 if (gst.countdown > 100) else 1].cam_anchor
				par.position = anchor.global_position
				par.basis = anchor.global_basis
			GameState.MATCH_STATE.CINEMATIC:
				var inst = CharaRend.insts
				var anchor = CharaRend.insts[int(gst.cinematic_is_p2)].cam_anchor
				par.position = anchor.global_position
				par.basis = anchor.global_basis
			_:
				var w = gst.wall
				par.position = pos0 + Vector3.RIGHT * ((w.x + w.y) * 0.5 - 5000) * 0.002
				par.basis = basis0
	else:
		par.position.x = 0.0

	ppl1cam.global_transform = par.global_transform
	ppl2cam.global_transform = par.global_transform
	ppl12cam.global_transform = par.global_transform
