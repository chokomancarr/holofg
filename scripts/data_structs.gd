class_name ST

static func coord2world(c: Vector2i, sz : Vector2):
	return Vector2(
		float(c.x) / 10000 * sz.x,
		sz.y - float(c.y) / 10000 * sz.x
	)
static func cmag2world(c: Vector2i, sz : Vector2):
	return Vector2(
		float(c.x) / 10000 * sz.x,
		float(c.y) / 10000 * sz.x
	)

class BoxInfo:
	var ty: BOX_TY
	var rect: Rect2i
	var rect_flip: Rect2i
	
	var hit_i: int = 0
	
	func get_rect(f):
		return rect_flip if f else rect
	
	func _init(ty, rect):
		self.ty = ty
		self.rect = rect
		self.rect_flip = Rect2i(rect)
		self.rect_flip.position.x = -self.rect_flip.position.x - self.rect_flip.size.x
	
	func hashed():
		return [
			ty, rect, hit_i
		].hash()

class BoxInfoFrame extends BoxInfo:
	var frame_start: int
	var frame_end: int
	
	func _init(box : BoxInfo, st, ed):
		self.ty = box.ty
		self.rect = box.rect
		self.rect_flip = box.rect_flip
		self.frame_start = st
		self.frame_end = ed

class _AttInfoBase:
	var ty := ATTACK_TY.MID

class AttInfo_Hit extends _AttInfoBase:
	var n_freeze: int
	var stun_block : int
	var stun_hit : int
	var push_hit : int
	var min_space : int
	var knock_ty := KNOCK_TY.NONE
	var punish_knock_ty := KNOCK_TY.NONE
	var dir := STUN_DIR.HEAD
	var cancels := CancelInfo.new()

class AttInfo_Grab extends _AttInfoBase:
	var opp_nf : int
	var fix_dist := 1000000
	var end_dpos : int
	var can_tech : bool
	var bounds_offset : DT.OffsetInfo

class CancelInfo:
	var everything: bool = false
	var normal_lmh: int = 3
	var all_specials: bool = false
	var super_1: bool = false
	var super_2: bool = false
	var rapid: bool = false
	var air_normals: bool = false
	var air_specials: bool = false
	var specials: Array[String] = []
	var targets: Array[String] = []
	var normals: Array[String] = []
	var from_t: int = 0
	
	static var _normal_strengths = [ "lmh", "mh", "h", "" ]
	
	static func from_all():
		return ObjUtil.fill(new(), [true])
	
	static func from_json(json : Dictionary):
		var res = new()
		if json.has("all_specials"):
			var sp = json.all_specials
			res.all_specials = sp
			res.super_1 = sp
			res.super_2 = sp
		if json.has("super"):
			var sp = json.super
			res.super_1 = sp < 2
			res.super_2 = sp > 0
		if json.has("normals"):
			for s in json.normals: res.normals.push_back(s)
		if json.has("targets"):
			for s in json.targets: res.targets.push_back(s)
		return res
	
	func can_sp(s : String):
		return everything || all_specials || specials.has(s)
	func can_nr(s : String):
		return everything || normals.has(s) || _normal_strengths[normal_lmh].contains(s[-1])
	func can_anr(s : String):
		return everything || _normal_strengths[normal_lmh].contains(s[-1])

class SpawnInfo:
	var frame: int
	var sig: String




enum STATE_TY {
	IDLE_5 = 0x0001,
	WALK_FWD_6 = 0x0011, WALK_BACK_4 = 0x0021,
	CROUCH_2 = 0x0003, CROUCH_BACK_2 = 0x0007,
	BLOCK_5b = 0x0100, BLOCK_CROUCH_2b = 0x0300,
	JUMP_7 = 0x0400, JUMP_8 = 0x1400, JUMP_9 = 0x2400, 
	STUN = 0x0800, ACTION = 0x1000
}

static var STATE_IDLE_BIT = 0x0001
static var STATE_CROUCH_BIT = 0x0002
static var STATE_BLOCK_BIT = 0x0100

enum BOX_TY {
	HIT = 1, HURT = 2, GRAB = 3, COLLISION = 4
}

static func get_box_color(ty : BOX_TY):
	match ty:
		BOX_TY.HIT:	return Color.DARK_RED
		BOX_TY.HURT: return Color.FOREST_GREEN
		BOX_TY.GRAB: return Color.DODGER_BLUE
		BOX_TY.COLLISION: return Color(Color.DARK_GRAY, 0.3)
		_: return Color.BLACK

enum ATTACK_PART {
	STARTUP, ACTIVE, RECOVERY, NONE
}
enum ATTACK_TY {
	NONE = 0, HIGH = 0x1000, MID = 0x1001, LOW = 0x1010, AIR = 0x1004, GRAB = 0x0100, AIR_GRAB = 0x0101, CMD_GRAB = 0x0102,
	_HIT_BIT = 0x1000, _GRAB_BIT = 0x0100
}
enum STUN_TY {
	BLOCK, PARRY, NORMAL, COUNTER, PUNISH_COUNTER
}
enum STUN_AIR_TY {
	RESET, JUGGLE
}
enum STUN_DIR {
	OVERHEAD, HEAD, HEAD_UP, HEAD_SIDE, BODY, BODY_UP, BODY_SIDE, LEG
}
enum KNOCK_TY {
	NONE, KNOCKDOWN, HARD_KNOCKDOWN, CRUSH_FWD, CRUSH_BACK, LIFT, LIFT_JUGGLE
}
enum BLOCK_TY {
	NONE = 0, HIGH = 0x1001, LOW = 0x1010,
	ALL #shouldnt happen in actual games, just for training mode for blocking all
}
