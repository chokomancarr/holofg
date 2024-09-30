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
	
	var _summon_data : Dictionary

class MoveInfo:
	var uid: int
	var name: String
	var alias_name: String
	var cmd: IN.InputCommand
	var n_frames: int
	var can_rapid: bool
	var boxes: Array[ST.BoxInfoFrame]
	var att_info: Array[ST._AttInfoBase]
	var summons: Array[SummonFrameInfo]
	var offsets : OffsetInfo
	var can_hold : bool = false
	var is_jump: bool = false
	var override_offsets : bool = true
	var land_recovery : int = 0
	var force_att_part := ST.ATTACK_PART.NONE
	var whiff: MoveInfo

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
	var att_info : ST.AttInfo_Hit
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

static func load_chara(chara_id):
	var res = CharaInfo.new()
	res._id = chara_id
	
	var data = (load("res://database/chara_data_%d.json" % chara_id) as JSON).data
	data.moves.normals.append_array([ "5l", "5m", "5h", "2l", "2m", "2h" ])
	data.moves.jump_normals.append_array([ "8.5l", "8.5m", "8.5h" ])
	data.moves.grabs.append_array([ "5g" ])
	
	var _summon_data = load("res://database/chara_summons_%d.json" % chara_id) as JSON
	if _summon_data:
		res._summon_data = _summon_data.data
	
	res.max_health = data.max_health
	
	res.idle_box = parse_box(data.frames.idle)
	res.crouch_box = parse_box(data.frames.crouch)
	
	res.walk_sp_fwd = data.params.walk[0]
	res.walk_sp_rev = data.params.walk[1]
	
	var dash = data.frames["66"]
	if dash:
		res.dash_nf_fwd = dash.n_frames
		res.dash_off_fwd = OffsetInfo.from_json(dash, res.dash_nf_fwd)
	
	if data.frames.has("214s"):
		res.moves_su_1 = _parse_move("214s", data.frames, res)
	
	if data.frames.has("236s"):
		res.moves_su_2 = _parse_move("236s", data.frames, res)
	
	for sp in data.moves.specials:
		res.moves_sp.push_back(_parse_move(sp, data.frames, res))
	
	for nr in data.moves.normals:
		res.moves_nr[nr] = _parse_move(nr, data.frames, res)
	
	for ta in data.moves.targets:
		var move = _parse_move(ta, data.frames, res)
		#move.name = move.name.rsplit(".")[-1]
		res.moves_tr[ta] = move
	
	for jn in data.moves.jump_normals:
		var move = _parse_move(jn, data.frames, res)
		move.override_offsets = false
		move.land_recovery = data.frames[jn].land_recovery
		res.moves_j_nr[jn] = move
	
	for gb in data.moves.grabs:
		res.grabs[gb] = _parse_move(gb, data.frames, res)
	
	return res

static var _move_uid = 0
static func _parse_move(nm : String, frames : Dictionary, cinfo : CharaInfo):
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
		move.can_rapid = src.rapid
	var att_info_ty = null
	if src.has("boxes"):
		for d in src.boxes:
			var bres = ST.BoxInfoFrame.new(
				parse_box(d),
				d.frame_start,
				d.frame_end
			)
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
			move.att_info.push_back(_parse_att_info(h, att_info_ty, nm))
	if src.has("summons"):
		for s in src.summons:
			var sres = SummonFrameInfo.new()
			sres.frame = s.f
			sres.summon = _get_summon(cinfo, s.name)
			move.summons.push_back(sres)
	
	if src.has("whiff"):
		move.whiff = _parse_move("whiff", src, cinfo)
	
	return move

static func _parse_att_info(h : Dictionary, ty : ST.BOX_TY, nm : String):
	var hres
	match ty:
		ST.BOX_TY.HIT:
			hres = ST.AttInfo_Hit.new()
			hres.n_freeze = h.n_freeze if h.has("n_freeze") else 10
			hres.stun_block = h.stun[0]
			hres.stun_hit = h.stun[1]
			if h.has("ty"): hres.ty = ST.ATTACK_TY.get(h.ty)
			if h.has("knock_ty"): hres.knock_ty = ST.KNOCK_TY.get(h.knock_ty)
			if h.has("cancel"): hres.cancels = ST.CancelInfo.from_json(h.cancel)
			else: hres.cancels = ST.CancelInfo.new()
			hres.cancels.normal_lmh = "lmh".find(nm[-1]) + 1
			if h.has("push"): hres.push_hit = h.push
			if h.has("minspace"): hres.min_space = h.minspace
			if h.has("dir"): hres.dir = ST.STUN_DIR.get(h.dir)
			if h.has("dmg"): hres.dmg = h.dmg
		ST.BOX_TY.GRAB:
			hres = ST.AttInfo_Grab.new()
			hres.ty = h.ty if h.has("ty") else ST.ATTACK_TY.GRAB
			hres.opp_nf = h.n_frames
			hres.fix_dist = h.fix_dist if h.has("fix_dist") else 10000000
			hres.end_dpos = h.end_dpos
			if h.has("bounds_offset"):
				hres.bounds_offset = OffsetInfo.from_json(h.bounds_offset, hres.opp_nf)
		ST.BOX_TY.HIT_SUPER:
			hres = ST.AttInfo_Super.new()
			hres.n_cinematic_start = h.n_cinematic_start
			hres.n_cinematic_hit : h.n_cinematic_hit
			
			hres.end_dpos = Vector2i(h.end_dpos[0], h.end_dpos[1])
			hres.end_dpos_opp = Vector2i(h.end_dpos_opp[0], h.end_dpos_opp[1])
			hres.n_end : h.n_end
			hres.n_end_opp : h.n_end_opp
			if h.has("end_opp_offset):
				hres.end_opp_offset : OffsetInfo.from_json(h.end_opp_offset, hres.n_end_opp)
			hres.end_opp_use_anim : h.end_opp_use_anim
		_:
			pass
	return hres

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
	res.att_info = _parse_att_info(o.att_info, ST.BOX_TY.HIT, "0h")
	res.att_info.detached = true
	if o.has("boxes"):
		for b in o.boxes:
			res.boxes.push_back(parse_box(b))
	
	cinfo.summons[nm] = res
	return res

static func parse_box(d):
	return ST.BoxInfo.new(ST.BOX_TY.get(d.ty), Rect2i(d.rect[0],d.rect[1],d.rect[2],d.rect[3]))
