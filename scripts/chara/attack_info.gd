class_name AttInfo

var box_ty := ST.BOX_TY.NONE
var ty := TY.NONE
var dmg := 1000
var gauge := 100
var detached := false

class Hit extends AttInfo:
	var n_freeze := 10
	var stun_block : int
	var stun_hit : int
	var push_hit : int
	var min_space : int
	var knock_ty := ST.KNOCK_TY.NONE
	var punish_knock_ty := ST.KNOCK_TY.NONE
	var dir := ST.STUN_DIR.HEAD
	var cancels := ST.CancelInfo.new()
	var force_air := ST.STUN_AIR_TY.NONE

enum TY {
	NONE = 0, HIGH = 0x1000, MID = 0x1001, LOW = 0x1010, AIR = 0x1004, GRAB = 0x0100, AIR_GRAB = 0x0101, CMD_GRAB = 0x0102,
	_HIT_BIT = 0x1000, _GRAB_BIT = 0x0100, _SUPER_1_BIT = 0x100000, _SUPER_2_BIT = 0x200000
}
const TY_PRIO = {
	TY.NONE: 0,
	TY.GRAB: 1,
	TY.AIR_GRAB: 1,
	TY.HIGH: 2,
	TY.MID: 2,
	TY.LOW: 2,
	TY.AIR: 2,
	TY.CMD_GRAB: 10
}


static func parse(h : Dictionary, ty : ST.BOX_TY, nm : String, use_lmh_cancel = false):
	var hres = new() if ty == ST.BOX_TY.GRAB else Hit.new()
	hres.box_ty = ty
	
	match ty:
		ST.BOX_TY.HIT:
			hres.ty = TY.get(h.ty) if h.has("ty") else TY.HIGH
			if h.has("n_freeze"): hres.n_freeze = h.n_freeze
			hres.stun_block = h.stun[0]
			hres.stun_hit = h.stun[1]
			if nm == "214s":
				hres.ty += TY._SUPER_1_BIT
			elif nm == "236s":
				hres.ty += TY._SUPER_2_BIT
			if h.has("knock_ty"): hres.knock_ty = ST.KNOCK_TY.get(h.knock_ty)
			if h.has("cancel"):
				if not h.cancel is String:
					hres.cancels = ST.CancelInfo.from_json(h.cancel)
				else:
					hres.cancels = ST.CancelInfo.new()
					use_lmh_cancel = false
			else: hres.cancels = ST.CancelInfo.new()
			if use_lmh_cancel:
				hres.cancels.normal_lmh = "lmh".find(nm[-1])
				hres.cancels.normal_except = nm
				hres.cancels.all_specials = true
				hres.cancels.super_1 = true
				hres.cancels.super_2 = true
			if h.has("push"): hres.push_hit = h.push
			if h.has("minspace"): hres.min_space = h.minspace
			if h.has("dir"): hres.dir = ST.STUN_DIR.get(h.dir)
			if h.has("dmg"): hres.dmg = h.dmg
			if h.has("force_air"): hres.force_air = ST.STUN_AIR_TY.get(h.force_air)
		ST.BOX_TY.GRAB:
			hres.ty = h.ty if h.has("ty") else TY.GRAB
		_:
			pass
	return hres
