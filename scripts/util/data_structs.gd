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
	var ty : BOX_TY
	var rect: Rect2i
	var rect_flip: Rect2i
	var flags : BOX_FLAGS
	
	var hit_i: int = 0
	
	func get_rect(p2):
		return rect_flip if p2 else rect
	
	static func from_info(d, flg = BOX_FLAGS.ALL):
		var res = new()
		res.ty = ST.BOX_TY.get(d.ty)
		res.rect = Rect2i(d.rect[0],d.rect[1],d.rect[2],d.rect[3])
		res.rect_flip = Rect2i(res.rect)
		res.rect_flip.position.x = -res.rect_flip.position.x - res.rect_flip.size.x
		res.flags = BOX_FLAGS.get(d.flags) if d.has("flags") else flg
		return res
	
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
		self.flags = box.flags
		self.frame_start = st
		self.frame_end = ed

class CancelInfo:
	var everything: bool = false
	var normal_lmh: int = 3
	var normal_except: String
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
		var res = new()
		res.everything = true
		return res
	
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
		return everything || normals.has(s) || (_normal_strengths[normal_lmh].contains(s[-1]) and (s != normal_except))
	func can_anr(s : String):
		return everything || _normal_strengths[normal_lmh].contains(s[-1])

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
	NONE = 0, HIT = 1, HURT = 2, GRAB = 3, PUSH = 4, CLASH = 5
}

enum BOX_FLAGS {
	NONE = 0,
	HIT = 1,
	THROW = 2,
	AIR_HIT = 4,
	PROJ_HIT = 8,
	HIT_INVUL = 0xffff - 1 - 4,
	THROW_INVUL = 0xffff - 2,
	AIR_INVUL = 0xffff - 4,
	PROJ_INVUL = 0xffff - 8,
	ALL = 0xffff
}

static func get_box_color(ty : BOX_TY):
	match ty:
		BOX_TY.HIT: return Color.DARK_RED
		BOX_TY.HURT: return Color.FOREST_GREEN
		BOX_TY.GRAB: return Color.DODGER_BLUE
		BOX_TY.PUSH: return Color(Color.DARK_GRAY, 0.3)
		BOX_TY.CLASH: return Color.DARK_GOLDENROD
		_: return Color.BLACK

enum ATTACK_PART {
	STARTUP, ACTIVE, RECOVERY, NONE
}
enum STUN_TY {
	BLOCK, PARRY, NORMAL, COUNTER, PUNISH_COUNTER
}
enum STUN_AIR_TY {
	NONE, RESET, JUGGLE, LIM_JUGGLE
}
enum STUN_DIR {
	OVERHEAD, HEAD, HEAD_UP, HEAD_SIDE, BODY, BODY_UP, BODY_SIDE, LEG
}
enum KNOCK_TY {
	NONE, KNOCKDOWN, HARD_KNOCKDOWN, CRUSH_FWD, CRUSH_BACK, LIFT, LIFT_JUGGLE
}
enum BLOCK_TY {
	NONE = 0, HIGH = 0x1001, LOW = 0x1010,
	ALL  #shouldnt happen in actual games, just for training mode
}
