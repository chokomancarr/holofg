class_name _CsStunBase extends _CsBase

var combo_scaling := 10000
var total_dmg := 0
var last_dmg := 0

var last_att_ty : AttInfo.TY

var next_scaling := 0

var eff_pos : Vector2i

func _clone(res):
	return ObjUtil.clone(self, super._clone(res),
		[ "combo_scaling", "total_dmg", "last_dmg", "last_att_ty", "next_scaling" ],
		[]
	)

func apply_scaling(old : _CsStunBase, hit : AttInfo.Hit):
	var scl = old.next_scaling if old else 0
	combo_scaling = ((old.combo_scaling if old else 10000) * (10000 - scl)) / 10000
	last_dmg = (combo_scaling * hit.dmg) / 10000
	total_dmg = (old.total_dmg if old else 0) + last_dmg
	
	next_scaling = AT.BASE_SCALING
	
	return last_dmg
