class_name PplOverlay extends Node

@export var viewport1 : SubViewport
@export var viewport2 : SubViewport
@export var viewport12 : SubViewport
@onready var ovl1 = $"ppl1" as TextureRect
@onready var ovl2 = $"ppl2" as TextureRect
@onready var ovl12 = $"ppl12" as TextureRect

static var sort_order = 0

var _sz = Vector2i.ZERO
func _process(dt):
	var sz = DisplayServer.screen_get_size()
	if sz != _sz:
		viewport1.size = sz
		viewport2.size = sz
		viewport12.size = sz
		_sz = sz
	
	viewport1.process_mode = Node.PROCESS_MODE_INHERIT if sort_order > -1 else Node.PROCESS_MODE_DISABLED
	viewport2.process_mode = Node.PROCESS_MODE_INHERIT if sort_order > -1 else Node.PROCESS_MODE_DISABLED
	viewport12.process_mode = Node.PROCESS_MODE_INHERIT if sort_order == -1 else Node.PROCESS_MODE_DISABLED

	ovl1.visible = sort_order > -1
	ovl2.visible = sort_order > -1
	ovl12.visible = sort_order == -1
	
	ovl2.z_index = sort_order * 2 + 1
