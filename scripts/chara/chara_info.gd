class_name DT

class CharaInfo:
	var _id: int
	var max_health: int
	var idle_box: ST.BoxInfo
	var crouch_box: ST.BoxInfo
	var walk_sp_fwd: int
	var walk_sp_rev: int
	var dash_off_fwd: OffsetInfo
	var dash_nf_fwd: int
	var moves_su_1: MoveInfo
	var moves_su_2: MoveInfo
	var moves_sp: Array[MoveInfo]
	var moves_nr: Dictionary
	var moves_tr: Dictionary
	var moves_j_nr: Dictionary
	var grabs: Dictionary
	var summons: Dictionary
	var accessories : Dictionary
	
	var _summon_data : Dictionary

class MoveInfo:
	var uid: int
	var name: String
	var alias_name: String
	var cmd: IN.InputCommand
	var n_frames: int
	var boxes: Array[ST.BoxInfoFrame]
	var end_dpos : int
	var bounds_offset : OffsetInfo
	var att_info: Array[AttInfo]
	var summons: Array[SummonFrameInfo]
	var offsets : OffsetInfo
	var override_offsets : bool = true
	var land_recovery : int = 0
	var whiff: MoveInfo
	var blocked: MoveInfo

class SummonFrameInfo:
	var frame: int
	var summon: SummonInfo

class SummonInfo:
	var uid : int
	var scene : String
	var n_hits : int = 1
	var hit_rate : int = 0
	var init_pos : Vector2i
	var velocity : Vector2i = Vector2i(0, 0)
	var lifetime : int = 1000
	var offsets : DT.OffsetInfo = null
	var att_info : AttInfo
	var boxes : Array[ST.BoxInfo]

class OffsetInfo:
	var vals = []
	var _hash : int
	
	func clone():
		var res = new()
		res.vals = vals.duplicate()
		res._hash = _hash
		return res
	
	static func from_json(o, nf):
		return from_keys(o.offsets, nf) if o.offsets_use_keyframes else from_vals(o.offsets, nf)
	
	static func from_vals(vs : Array, n : int):
		var res = new()
		for v in vs:
			res.vals.push_back(Vector2i(v[0], v[1]))
		return res.pad(n)
	
	static func from_keys(ks : Array, n : int):
		var res = new()
		var m = ks.size() - 1
		var k = 0
		var ls = Vector2i(ks[0][1][0], ks[0][1][1])
		for i in range(n):
			if k < m and ks[k+1][0] == i:
				k += 1
				ls = Vector2i(ks[k][1][0], ks[k][1][1])
			res.vals.push_back(Vector2i(ls))
		return res.pad(n)
	
	func pad(n):
		var v = vals.back()
		for _i in range(n - vals.size()):
			vals.push_back(Vector2i(v))
		_hash = vals.hash()
		return self
	
	func eval(i):
		return vals[i]
	
	func hashed():
		return _hash

class AccessInfo:
	var scene : String
	var anchor : String
	func _init(s, a):
		scene = s
		anchor = a


static func load_chara(chara_id):
	var res = CharaInfo.new()
	res._id = chara_id
	
	var data = (load("res://database/chara_data_%d.json" % chara_id) as JSON).data
	data.moves.normals.append_array([ "5l", "5m", "5h", "2l", "2m", "2h" ])
	data.moves.jump_normals.append_array([ "8.5l", "8.5m", "8.5h" ])
	data.moves.grabs.append_array([ "4g", "5g" ])
	
	var _summon_data = load("res://database/chara_summons_%d.json" % chara_id) as JSON
	if _summon_data:
		res._summon_data = _summon_data.data
	
	res.max_health = data.max_health
	
	res.idle_box = ST.BoxInfo.from_info(data.frames.idle, ST.BOX_FLAGS.ALL)
	res.crouch_box = ST.BoxInfo.from_info(data.frames.crouch, ST.BOX_FLAGS.ALL)
	
	res.walk_sp_fwd = data.params.walk[0]
	res.walk_sp_rev = data.params.walk[1]
	
	var dash = data.frames["66"]
	if dash:
		res.dash_nf_fwd = dash.n_frames
		res.dash_off_fwd = OffsetInfo.from_json(dash, res.dash_nf_fwd)
	
	if data.frames.has("214s"):
		res.moves_su_1 = _parse_move("214s", data.frames, res, ST.BOX_FLAGS.HIT)
	
	if data.frames.has("236s"):
		res.moves_su_2 = _parse_move("236s", data.frames, res, ST.BOX_FLAGS.HIT)
	
	for sp in data.moves.specials:
		res.moves_sp.push_back(_parse_move(sp, data.frames, res, ST.BOX_FLAGS.HIT))
	
	for nr in data.moves.normals:
		res.moves_nr[nr] = _parse_move(nr, data.frames, res, ST.BOX_FLAGS.HIT, true)
	
	for ta in data.moves.targets:
		var move = _parse_move(ta, data.frames, res, ST.BOX_FLAGS.HIT)
		#move.name = move.name.rsplit(".")[-1]
		res.moves_tr[ta] = move
	
	for jn in data.moves.jump_normals:
		var move = _parse_move(jn, data.frames, res, ST.BOX_FLAGS.AIR_HIT)
		move.override_offsets = false
		move.land_recovery = data.frames[jn].land_recovery
		res.moves_j_nr[jn] = move
	
	for gb in data.moves.grabs:
		res.grabs[gb] = _parse_move(gb, data.frames, res, ST.BOX_FLAGS.THROW)
	
	if data.has("accessories"):
		res.accessories = _parse_access(data.accessories)
	
	return res

static var _move_uid = 0
static func _parse_move(nm : String, frames : Dictionary, cinfo : CharaInfo, bflags, use_lmh_cancel = false):
	if not frames.has(nm):
		assert(false, "missing frame data for " + nm + "!")
	var move = MoveInfo.new()
	move.uid = _move_uid
	_move_uid += 1
	var src = frames[nm]
	move.name = (src.anim_name if src.has("anim_name") else nm).replace(".", "_")
	move.cmd = IN.InputCommand.from_string(nm)
	move.n_frames = src.n_frames
	if src.has("alias"):
		move.alias_name = src.alias
	if src.has("rapid"):
		nm = nm.rsplit(".")[-1]
		use_lmh_cancel = true
	if src.has("end_dpos"):
		move.end_dpos = src.end_dpos
	if src.has("bounds_offset"):
		move.bounds_offset = OffsetInfo.from_json(src.bounds_offset, move.n_frames)
	var att_info_ty = null
	if src.has("boxes"):
		for d in src.boxes:
			var bres = ST.BoxInfoFrame.new(
				ST.BoxInfo.from_info(d),
				d.frame_start,
				d.frame_end
			)
			if bres.flags == ST.BOX_FLAGS.ALL:
				if bres.ty == ST.BOX_TY.HIT or bres.ty == ST.BOX_TY.GRAB:
					bres.flags = bflags
			att_info_ty = bres.ty
			if d.has("att_info"):
				bres.hit_i = d.att_info
			else:
				bres.hit_i = 0
			move.boxes.push_back(bres)
	if src.has("offsets"):
		move.offsets = OffsetInfo.from_json(src.offsets, move.n_frames)
	if att_info_ty and src.has("att_info"):
		for h in src.att_info:
			move.att_info.push_back(AttInfo.parse(h, att_info_ty, nm, use_lmh_cancel))
	if src.has("summons"):
		for s in src.summons:
			var sres = SummonFrameInfo.new()
			sres.frame = s.f
			sres.summon = _get_summon(cinfo, s.name)
			move.summons.push_back(sres)
	
	if src.has("whiff"):
		move.whiff = _parse_move("whiff", src, cinfo, ST.BOX_FLAGS.HIT)
	if src.has("blocked"):
		move.blocked = _parse_move("blocked", src, cinfo, ST.BOX_FLAGS.HIT)
	
	return move

static var _summon_uid = 0
static func _get_summon(cinfo : CharaInfo, nm : String):
	if cinfo.summons.has(nm):
		return cinfo.summons[nm]
	
	var o = cinfo._summon_data[nm]
	var res = SummonInfo.new()
	res.uid = _summon_uid
	res.scene = o.scene
	if o.has("lifetime"): res.lifetime = o.lifetime
	if o.has("init_pos"): res.init_pos = Vector2i(o.init_pos[0], o.init_pos[1])
	if o.has("velocity"): res.velocity = Vector2i(o.velocity[0], o.velocity[1])
	if o.has("offsets"): res.offsets = OffsetInfo.from_json(o.offsets, res.lifetime)
	if o.has("n_hits"): res.n_hits = o.n_hits
	if o.has("hit_rate"): res.hit_rate = o.hit_rate
	res.att_info = AttInfo.parse(o.att_info, ST.BOX_TY.HIT, "0h")
	res.att_info.detached = true
	if o.has("boxes"):
		for b in o.boxes:
			res.boxes.push_back(ST.BoxInfo.from_info(b))
	
	cinfo.summons[nm] = res
	return res

static func _parse_access(src):
	var res = {}
	for k in src:
		var spwns = src[k] as Dictionary
		res[k] = spwns.keys().map(func (k2):
			return AccessInfo.new(k2, spwns[k2])
		)
	return res
