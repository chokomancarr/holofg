class_name CharaAccess extends Node

var last_state : String
var last_objs : Array[Node]

func step(pst : PlayerState, cr : CharaRend):
	var st = pst.state._STATE_NAME
	if st != last_state:
		last_state = st
		for o in last_objs:
			o.queue_free()
		last_objs = []
		var ac = pst._info.accessories
		if ac.has(st):
			var spwns = ac[st]
			for spwn : DT.AccessInfo in spwns:
				var nd = load("res://chara_scenes/accessories/%s.tscn" % spwn.scene).instantiate() as Node3D
				cr.attach_to_anchor(nd, spwn.anchor)
				cr._set_layer(nd)
				last_objs.push_back(nd)
