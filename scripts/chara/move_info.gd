class_name MoveInfo extends _Base

class _Base:
	var uid: int						#unique identifier for this move
	var name: String					#input name (animation name)
	var n_frames: int
	var boxes: Array[ST.BoxInfoFrame]
	var end_dpos : int					#how much to move fwd / back
	var bounds_offset : OffsetInfo		#for camera follow / wall push
	var offsets : OffsetInfo			#position change during move
	var override_offsets := true		#if false, offsets from the previous move is continued (for jumping moves)

class Opp extends _Base:
	var lock_to_p1 : bool
	var lock_to_floor : bool


class Cinema:
	var show_opp : bool
	var override_camera : bool
	var n_frames : int
	
	var bounds_offset : DT.OffsetInfo
	var bounds_offset_opp : DT.OffsetInfo
	
	var end_dpos := Vector2i.ZERO
	var end_dpos_opp := Vector2i.ZERO


var alias_name: String				#shortcut input name
var cmd: IN.InputCommand
var n_frames: int
var att_info: Array[AttInfo]
var summons: Array[SummonInfoFrame]
var land_recovery : int = 0
var move_connd: MoveInfo
var move_connd_opp: Opp

var cine_startup : Cinema #played before startup
var cine_hit : Cinema #played on hit

static var _move_uid = 0
static func parse(nm : String, frames : Dictionary, cinfo : DT.CharaInfo, bflags, use_lmh_cancel = false):
	if not frames.has(nm):
		assert(false, "missing frame data for " + nm + "!")
	var move = new()
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
			var sres = SummonInfoFrame.new()
			sres.frame = s.f
			sres.summon = _get_summon(cinfo, s.name)
			move.summons.push_back(sres)
	
	if src.has("whiff"):
		move.whiff = _parse_move("whiff", src, cinfo, ST.BOX_FLAGS.HIT)
	if src.has("blocked"):
		move.blocked = _parse_move("blocked", src, cinfo, ST.BOX_FLAGS.HIT)
	
	return move