extends Node

var pfb = preload("res://scenes/popup.tscn")
var scn : Control

var lbl : Label
var bt : Button

var showing = false

func _ready() -> void:
	_ready2.call_deferred()

func _ready2():
	scn = pfb.instantiate()
	get_parent().add_child(scn)
	lbl = scn.get_node("%txt")
	bt = scn.get_node("%bt")
	scn.visible = false

func show(txt):
	showing = true
	scn.visible = true
	lbl.text = txt
	await bt.pressed
	scn.visible = false
	showing = false
