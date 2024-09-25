extends Node

@onready var root = $"/root"
@onready var current = get_node_or_null("/root/main")

var MAIN_MENU = preload("res://scenes/main_menu.tscn")
#var ONLINE_LOBBY = preload("res://scenes/main_menu.tscn")
var GAME = preload("res://scenes/game.tscn")

func load(scn):
	current.queue_free()
	current = scn.instantiate()
	root.add_child(current)