class_name T1 extends Node

var __ser_copy = null

var a = 1
var b = 2

var __ser_clone = null

var c = 3

var __ser_none = null

var g = 5


func _clone(res):
	return clone2(self, res)

func tohash():
	return [
		_tohash()
	]

func _tohash():
	pass


func clone2(src : Object, dst : Object):
	for p in src.get_property_list():
		print_debug(p.name)
	return dst
