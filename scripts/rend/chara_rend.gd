class_name CharaRend extends Node3D

@export var is_p1 = true

@onready var mdl = get_child(0) as Node3D
@onready var arm = mdl.get_node("Armature") as Node3D
@onready var anim = mdl.get_node("AnimationPlayer") as AnimationPlayer
@onready var anim_ctrl = anim.get_node("anim_player") as CharaAnimPlayer

func _process(delta):
	if not GameMaster.game_state:
		return
	
	var pst = GameMaster.game_state.p1 if is_p1 else GameMaster.game_state.p2
	position.x = (pst.pos.x - 5000) * 0.002
	position.y = pst.pos.y * 0.002
	
	arm.rotation.y = -PI / 2 if pst.action_is_p2 else PI / 2
	
	anim_ctrl.step(GameMaster.game_state, pst, delta)
