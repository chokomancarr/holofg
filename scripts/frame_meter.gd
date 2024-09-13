class_name FrameMeter
extends Node

@onready var p1 = $"p1/gc"
@onready var p2 = $"p2/gc"

var p1_cells : Array[ColorRect] = []
var p2_cells : Array[ColorRect] = []


var pos = 0

func _ready():
	for i in range(60):
		var c = ColorRect.new()
		c.color = Color.TRANSPARENT
		c.custom_minimum_size = Vector2(10, 10)
		p1.add_child(c)
		p1_cells.push_back(c)
		
		c = ColorRect.new()
		c.color = Color.TRANSPARENT
		c.custom_minimum_size = Vector2(10, 10)
		p2.add_child(c)
		p2_cells.push_back(c)

func clear():
	for c in p1_cells:
		c.color = Color.TRANSPARENT
	for c in p2_cells:
		c.color = Color.TRANSPARENT

func step(p1 : PlayerState, p2 : PlayerState):
	var r1 = p1.state.get_frame_meter_color()
	var r2 = p2.state.get_frame_meter_color()
	if not r1 and not r2:
		pos = -1
		return
	
	if r1 and p1.state.state_t == 1:
		r1 = r1.darkened(0.2)
	if r2 and p2.state.state_t == 1:
		r2 = r2.darkened(0.2)
	
	if pos == -1:
		pos = 0
		clear()
	
	if r1:
		p1_cells[pos].color = r1
	if r2:
		p2_cells[pos].color = r2
	
	pos += 1
	if pos == 60:
		pos = 0
	p1_cells[pos].color = Color.TRANSPARENT
	p2_cells[pos].color = Color.TRANSPARENT
