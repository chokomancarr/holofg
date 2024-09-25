extends Node

@onready var root = $"/root"
@onready var current = get_node_or_null("/root/main")

@onready var MAIN_MENU = load("res://scenes/main_menu.tscn")
#var ONLINE_LOBBY = preload("res://scenes/main_menu.tscn")
@onready var GAME = load("res://scenes/game.tscn")

func load_scene(scn):
	current.name = "_goodbye_main"
	current.queue_free()
	current = scn.instantiate()
	root.add_child(current)
