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


class SummonInfoFrame:
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
		res.moves_su_1 = MoveInfo.parse("214s", data.frames, res, ST.BOX_FLAGS.HIT)
	
	if data.frames.has("236s"):
		res.moves_su_2 = MoveInfo.parse("236s", data.frames, res, ST.BOX_FLAGS.HIT)
	
	for sp in data.moves.specials:
		var move = MoveInfo.parse(sp, data.frames, res, ST.BOX_FLAGS.HIT)
		if data.frames[sp].has("land_recovery"):
			move.land_recovery = data.frames[sp].land_recovery
		res.moves_sp.push_back(move)
	
	for nr in data.moves.normals:
		res.moves_nr[nr] = MoveInfo.parse(nr, data.frames, res, ST.BOX_FLAGS.HIT, true)
	
	for ta in data.moves.targets:
		var move = MoveInfo.parse(ta, data.frames, res, ST.BOX_FLAGS.HIT)
		#move.name = move.name.rsplit(".")[-1]
		res.moves_tr[ta] = move
	
	for jn in data.moves.jump_normals:
		var move = MoveInfo.parse(jn, data.frames, res, ST.BOX_FLAGS.AIR_HIT)
		move.override_offsets = false
		move.land_recovery = data.frames[jn].land_recovery
		res.moves_j_nr[jn] = move
	
	for gb in data.moves.grabs:
		res.grabs[gb] = MoveInfo.parse(gb, data.frames, res, ST.BOX_FLAGS.THROW)
	
	if data.has("accessories"):
		res.accessories = _parse_access(data.accessories)
	
	return res


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
