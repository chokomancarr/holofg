class_name DT

class CharaInfo:
	var max_health: int
	var idle_box: ST.BoxInfo
	var crouch_box: ST.BoxInfo
	var walk_sp_fwd: int
	var walk_sp_rev: int
	var dash_off_fwd: OffsetInfo
	var dash_nf_fwd: int
	var moves_sp: Array[MoveInfo]
	var moves_nr: Dictionary
	var moves_tr: Dictionary
	var moves_j_nr: Dictionary
	var grabs: Dictionary

class MoveInfo:
	var name: String
	var alias_name: String
	var cmd: IN.InputCommand
	var n_frames: int
	var can_rapid: bool
	var boxes: Array[ST.BoxInfoFrame]
	var hit_info: Array[ST.HitInfo]
	var opp_info: ST.OppAnimInfo
	var spawn_info: Array[ST.SpawnInfo]
	var offsets : OffsetInfo
	var can_hold : bool = false
	var is_jump: bool = false
	var override_offsets : bool = true
	var land_recovery : int = 0
	var force_att_part := ST.ATTACK_PART.NONE
	
	var whiff: MoveInfo

class OffsetInfo:
	var vals = []
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
		return self
	
	func eval(i):
		return vals[i]

static func load_chara(chara_id):
	var data = (load("res://database/chara_data_%d.json" % chara_id) as JSON).data
	data.moves.normals.append_array([ "5l", "5m", "5h", "2l", "2m", "2h" ])
	data.moves.jump_normals.append_array([ "8.5l", "8.5m", "8.5h" ])
	data.moves.grabs.append_array([ "5g" ])
	
	var res = CharaInfo.new()
	
	res.max_health = data.max_health
	
	res.idle_box = parse_box(data.frames.idle)
	res.crouch_box = parse_box(data.frames.crouch)
	
	res.walk_sp_fwd = data.params.walk[0]
	res.walk_sp_rev = data.params.walk[1]
	
	var dash = data.frames["66"]
	if dash:
		res.dash_nf_fwd = dash.n_frames
		res.dash_off_fwd = OffsetInfo.from_json(dash, res.dash_nf_fwd)
	
	for sp in data.moves.specials:
		res.moves_sp.push_back(_parse_move(sp, data.frames))
	
	for nr in data.moves.normals:
		res.moves_nr[nr] = _parse_move(nr, data.frames)
	
	for tr in data.moves.targets:
		var move = _parse_move(tr, data.frames)
		#move.name = move.name.rsplit(".")[-1]
		res.moves_tr[tr] = move
	
	for jn in data.moves.jump_normals:
		var move = _parse_move(jn, data.frames)
		move.override_offsets = false
		move.land_recovery = data.frames[jn].land_recovery
		res.moves_j_nr[jn] = move
	
	for gb in data.moves.grabs:
		res.grabs[gb] = _parse_move(gb, data.frames)
	
	return res

static func _parse_move(nm : String, frames : Dictionary):
	if not frames.has(nm):
		assert(false, "missing frame data for " + nm + "!")
	var move = MoveInfo.new()
	var src = frames[nm]
	move.name = (src.anim_name if src.has("anim_name") else nm).replace(".", "_")
	move.cmd = IN.InputCommand.from_string(nm)
	move.n_frames = src.n_frames
	if src.has("alias"):
		move.alias_name = src.alias
	if src.has("rapid"):
		move.can_rapid = src.rapid
	if src.has("boxes"):
		for d in src.boxes:
			var bres = ST.BoxInfoFrame.new(
				parse_box(d),
				d.frame_start,
				d.frame_end
			)
			match bres.ty:
				ST.BOX_TY.HIT:
					if d.has("hit_info"):
						bres.hit_i = roundi(d.hit_info)
				_:
					pass
			move.boxes.push_back(bres)
	if src.has("offsets"):
		move.offsets = OffsetInfo.from_json(src.offsets, move.n_frames)
	if src.has("hit_info"):
		for h in src.hit_info:
			var hres = ST.HitInfo.new()
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
			move.hit_info.push_back(hres)
	if src.has("opp_info"):
		var h = src.opp_info
		var hres = ST.OppAnimInfo.new()
		hres.nf = h.n_frames
		hres.fix_dist = h.fix_dist if h.has("fix_dist") else 10000000
		move.opp_info = hres
	if src.has("spawns"):
		for s in src.spawns:
			var sres = ST.SpawnInfo.new()
			sres.frame = s.f
			sres.sig = s.sig
			move.spawn_info.push_back(sres)
	
	if src.has("whiff"):
		move.whiff = _parse_move("whiff", src)
	
	return move

static func parse_box(d):
	return ST.BoxInfo.new(ST.BOX_TY.get(d.ty), Rect2i(d.rect[0],d.rect[1],d.rect[2],d.rect[3]))
