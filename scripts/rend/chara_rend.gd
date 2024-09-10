extends Node

@export var is_p1 = true

@onready var par = get_parent() as Node3D
@onready var arm = par.get_node("Armature") as Node3D
@onready var anim_ctrl = par.get_node("AnimationPlayer/ctrl") as CharaAnimPlayer

func _process(delta):
	if not GameMaster.game_state:
		return
	
	var pst = GameMaster.game_state.p1 if is_p1 else GameMaster.game_state.p2
	par.position.x = (pst.pos.x - 5000) * 0.002
	par.position.y = pst.pos.y * 0.002
	
	#par.scale.x = -1 if pst.action_is_p2 else 1
	arm.rotation.y = -PI / 2 if pst.action_is_p2 else PI / 2
	
	anim_ctrl.step(pst, delta)
