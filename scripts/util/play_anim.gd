extends Node

@onready var par = get_parent() as AnimationPlayer
@export var anim : String

func _ready():
	par.play(anim)
