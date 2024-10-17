class_name MoveInfo extends _Base

class _Base:
	var uid: int						#unique identifier for this move
	var name: String					#input name (animation name)
	var n_frames: int
	var boxes: Array[ST.BoxInfoFrame]
	var end_dpos : Vector2i				#how much to move fwd / back
	var bounds_offset :DT.OffsetInfo	#for camera follow / wall push
	var offsets : DT.OffsetInfo			#position change during move
	var override_offsets := true		#if false, offsets from the previous move is continued (for jumping moves)

class Opp extends _Base:
	var lock_to_p1 : bool
	var lock_to_floor : bool


class Cinema:
	var anim_name : String
	var anim_name_opp : String
	var n_frames : int
	var end_dpos := Vector2i.ZERO
	var end_dpos_opp := Vector2i.ZERO


var alias_name: String				#shortcut input name
var cmd: IN.InputCommand
var att_info: Array[AttInfo]
var summons: Array[DT.SummonInfoFrame]
var land_recovery : int = 0
var move_connd: MoveInfo
var move_connd_opp: Opp

var cine_startup : Cinema #played before startup
var cine_hit : Cinema #played on hit

static var _move_uid = 0
static func parse(nm : String, frames : Dictionary, cinfo : DT.CharaInfo, bflags, use_lmh_cancel = false, move = new()):
	if not frames.has(nm):
		assert(false, "missing frame data for " + nm + "!")
	move.uid = _move_uid
	_move_uid += 1
	var src = frames[nm]
	move.name = (src.anim_name if src.has("anim_name") else nm).replace(".", "_")
	var cmd = IN.InputCommand.from_string(nm)
	if cmd:
		move.cmd = cmd
	move.n_frames = src.n_frames
	if src.has("alias"):
		move.alias_name = src.alias
	if src.has("rapid"):
		nm = nm.rsplit(".")[-1]
		use_lmh_cancel = true
	if src.has("end_dpos"):
		if src.end_dpos is Array:
			move.end_dpos = Vector2i(src.end_dpos[0], src.end_dpos[1])
		else:
			move.end_dpos = Vector2i(src.end_dpos, 0)
	if src.has("bounds_offset"):
		move.bounds_offset = DT.OffsetInfo.from_json(src.bounds_offset, move.n_frames)
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
		move.offsets = DT.OffsetInfo.from_json(src.offsets, move.n_frames)
	if att_info_ty and src.has("att_info"):
		for h in src.att_info:
			move.att_info.push_back(AttInfo.parse(h, att_info_ty, nm, use_lmh_cancel))
	if src.has("summons"):
		for s in src.summons:
			var sres = DT.SummonInfoFrame.new()
			sres.frame = s.f
			sres.summon = DT._get_summon(cinfo, s.name)
			move.summons.push_back(sres)
	
	for cine in [ "cine_startup", "cine_hit" ]:
		if src.has(cine):
			const cps = [
				"anim_name", "anim_name_opp", "n_frames", "end_dpos", "end_dpos_opp"
			]
			var h2 = src[cine]
			var cin = Cinema.new()
			for cp in cps:
				if h2.has(cp):
					var v = h2[cp]
					cin[cp] = Vector2i(v[0], v[1]) if v is Array else v
			if h2.has("end_bounds_offset_opp"):
				cin.end_bounds_offset_opp = DT.OffsetInfo.from_json(h2.end_bounds_offset_opp, cin.n_anim_end_opp)
			move[cine] = cin
	
	if src.has("connd"):
		move.move_connd = parse("connd", src, cinfo, ST.BOX_FLAGS.HIT)
	
	if src.has("connd_opp"):
		var res = Opp.new()
		parse("connd_opp", src, cinfo, ST.BOX_FLAGS.HIT, false, res)
		move.move_connd_opp = res
	
	return move
