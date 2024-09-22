class_name _CsStunBase extends _CsBase

var combo_scaling := 10000
var total_dmg := 0
var last_dmg := 0

var last_att_ty : ST.ATTACK_TY

var next_scaling := 0

func apply_scaling(old : _CsStunBase, hit : ST.AttInfo_Hit):
	var scl = old.next_scaling if old else 0
	combo_scaling = ((old.combo_scaling if old else 10000) * (10000 - scl)) / 10000
	last_dmg = (combo_scaling * hit.dmg) / 10000
	total_dmg = (old.total_dmg if old else 0) + last_dmg
	
	next_scaling = AT.BASE_SCALING
	
	return last_dmg
