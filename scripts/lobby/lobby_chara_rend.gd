class_name LobbyCharaRend extends Node

@export var p1 = true
@onready var mdl = get_child(0) as Node3D
@onready var arm = mdl.get_node("Armature") as Node3D
@onready var anim = mdl.get_node("AnimationPlayer") as AnimationPlayer


func play():
	var flp = "me/" if p1 else "me_flipped/"
	anim.play(flp + "lobby_idle")
