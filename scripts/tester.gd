extends Node

func _ready():
	var t1 = T2.new()
	var t1c = t1._clone(T2.new())
	
	print_debug(hash(t1.tohash()), " vs ", hash(t1c.tohash()))
