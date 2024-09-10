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

#class GameState:
	#var p1: PlayerState
	#var p2: PlayerState
	#var freeze_t: int = 0
	#var freeze_n: int = 0
	#var freeze_canbuffer := false
	#var countdown: int = -1#99 * 60 + 59
	#var wall = Vector2i(0, 10000)
	#
	#static func from_players(p1, p2):
		#var res = new()
		#res.p1 = p1
		#res.p2 = p2
		#return res
#
	#static func from_info(info_p1 : DT.CharaInfo, info_p2 : DT.CharaInfo):
		#return from_players(
			#PlayerState.create(info_p1, true),
			#PlayerState.create(info_p2, false)
		#)
	#
	#func is_frozen():
		#return freeze_t < freeze_n
	#
	#func freeze(n, canbuf = false):
		#freeze_t = 0
		#freeze_n = n
		#freeze_canbuffer = canbuf


#class PlayerState:
	#var _info: DT.CharaInfo
	#
	#var input_history: Array[IN.InputState] = []
	#
	##serialized
	#var bar_health: int
	#var bar_super: int = 0
	#
	#var pos: Vector2i
	#var state: STATE_TY = STATE_TY.IDLE_5
	#var action_name: String = "5"
	#
	#var check_land := false
	#
	#var state_t: int = 0
	#var offset_dt: int = 0
	#var stun_t: int = 0
	#
	#var stun_standing: bool
	#var stun_dir: STUN_DIR
	#
	#var next_action: DT.MoveInfo
	#
	#var att_processed: bool = false
	#
	#var pos_is_p2: bool
	#var action_is_p2: bool
	#
	##calculated
	#var current_action: DT.MoveInfo
	#var boxes: Array[BoxInfo] = []
	#var move_name: String = "5"
	#var att_part: ATTACK_PART
	#var current_att: int
	#var current_offsets: DT.OffsetInfo
	#
	#static func create(info : DT.CharaInfo, is_p1 : bool) -> PlayerState:
		#var res = PlayerState.new()
		#res._info = info
		#res.bar_health = info.max_health
		#res.input_history = [ IN.InputState.new() ] as Array[IN.InputState]
		#res.pos = Vector2i(4000 if is_p1 else 6000, 0)
		#res.pos_is_p2 = !is_p1
		#res.action_is_p2 = !is_p1
		#res.boxes = [info.idle_box] as Array[BoxInfo]
		#return res
	#
	#static func from(src: PlayerState) -> PlayerState:
		#var res = ObjUtil.clone(src, new())
		#res.input_history = src.input_history.slice(0, 100, 1, true) as Array[IN.InputState]
		#return res
	#
	#func serialize() -> Dictionary:
		#return {
		#}
	#static func deserialize(d : Dictionary):
		#var res = new()
		#return res

class BoxInfo:
	var ty: BOX_TY
	var rect: Rect2i
	
	var hit_i: int = 0
	
	func _init(ty, rect):
		self.ty = ty
		self.rect = rect

class BoxInfoFrame extends BoxInfo:
	var frame_start: int
	var frame_end: int
	
	func _init(box : BoxInfo, st, ed):
		self.ty = box.ty
		self.rect = box.rect
		self.frame_start = st
		self.frame_end = ed

class HitInfo:
	var stun_block : int
	var stun_hit : int
	var push_hit : int
	var min_space : int
	var ty := ATTACK_TY.MID
	var knock_ty := KNOCK_TY.NONE
	var punish_knock_ty := KNOCK_TY.NONE
	var cancels := CancelInfo.new()

class CancelInfo:
	var everything: bool = false
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
		return everything || normals.has(s)

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
	HIT = 0, HURT = 1, GRAB = 2, COLLISION = 3
}

static func get_box_color(ty : BOX_TY):
	match ty:
		BOX_TY.HIT:	return Color.DARK_RED
		BOX_TY.HURT: return Color.FOREST_GREEN
		BOX_TY.COLLISION: return Color(Color.DARK_GRAY, 0.3)
		_: return Color.BLACK

enum ATTACK_PART {
	STARTUP, ACTIVE, RECOVERY, NONE
}
enum ATTACK_TY {
	HIGH, MID, LOW, GRAB
}
enum STUN_TY {
	NORMAL, COUNTER, PUNISH_COUNTER
}
enum STUN_DIR {
	OVERHEAD, HEAD, HEAD_UP, HEAD_SIDE, BODY, BODY_UP, BODY_SIDE, LEG
}
enum KNOCK_TY {
	NONE, KNOCKDOWN, HARD_KNOCKDOWN, CRUSH_FWD, CRUSH_BACK, LIFT, LIFT_JUGGLE
}
