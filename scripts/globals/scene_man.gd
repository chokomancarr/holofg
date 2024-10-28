extends Node

@onready var root = $"/root"
@onready var current = get_node_or_null("/root/main")

@onready var MAIN_MENU = load("res://scenes/main_menu.tscn")
@onready var LOBBY_TRAIN = load("res://scenes/lobby_training.tscn")
@onready var LOBBY_ONLINE = load("res://scenes/lobby_online.tscn")
@onready var GAME = load("res://scenes/game.tscn")
@onready var PRABUT = load("res://scenes/pressanybutton.tscn")

var _rel = Node.new()

func _ready():
	_ready2.call_deferred()

func _ready2():
	current.add_sibling(_rel)

func load_scene(scn):
	current.name = "_goodbye_main"
	current.queue_free()
	current = scn.instantiate()
	_rel.add_sibling(current)
