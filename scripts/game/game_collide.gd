class_name GameCollider

const CHARA_DIST = 300
const CHARA_HALF_HEIGHT = 500
const CHARA_HALF_HEIGHT_CR = 300
const WALL_W = 2000

const GAUGE_BLOCK = [5, 3]
const GAUGE_HIT = [10, 7]
const GAUGE_PARRY = [5, 15]

static func step(game_state : GameState):
	var p1 = game_state.p1
	var p2 = game_state.p2
	
	var dist = _proc_push(game_state)

	var _h1 = _check_hit(p1, p2)
	var _h2 = _check_hit(p2, p1)
	var o = {
		"hit1" : _h1[0] as ST._AttInfoBase if _h1 else null,
		"hit2" : _h2[0] as ST._AttInfoBase if _h2 else null,
		"push1" : _h1[1] if _h1 else null,
		"push2" : _h2[1] if _h2 else null,
		"pos1" : _h1[2] if _h1 else null,
		"pos2" : _h2[2] if _h2 else null,
		"freeze" : 0
	}
	#if hit1 or hit2:
		#if hit1:
			#if game_state.p1.state.query_stun() != ST.STUN_TY.PUNISH_COUNTER\
			#and game_state.p1.state.query_stun() != ST.STUN_TY.PUNISH_COUNTER:
				#game_state.p1.state = CsGrabTech.new()
				#game_state.p2.state = CsGrabTech.new()
				#return

	var _inc_gauge = func (p : PlayerState, opp : PlayerState, inc : int, ratio : Array):
		opp.bar_super += (inc * ratio[0]) / 10
		p.bar_super += (inc * ratio[1]) / 10

	var apply_hit = func (p : PlayerState, opp : PlayerState, hit : ST._AttInfoBase, push : bool, eff_pos : Vector2i):
		var counter_ty = p.state.query_stun()
		if (hit.ty & ST.ATTACK_TY._HIT_BIT) > 0:
			if p.state.airborne:
				var sto = p.state as _CsStunBase
				var jug = (counter_ty != ST.STUN_TY.NORMAL) or (sto is CsStunAir and sto.ty == ST.STUN_AIR_TY.JUGGLE)
				p.state = CsStunAir.new(p, ST.STUN_AIR_TY.JUGGLE if jug else ST.STUN_AIR_TY.RESET)
				var dmg = (p.state as _CsStunBase).apply_scaling(sto, hit as ST.AttInfo_Hit)
				p.bar_health = maxi(p.bar_health - dmg, 0)
				p.state.eff_pos = eff_pos

				_inc_gauge.call(p, opp, hit.gauge, GAUGE_HIT)
			else:
				match counter_ty:
					ST.STUN_TY.BLOCK:
						var block_ty = p.state.block_state
						var canblock = (hit.ty & ~block_ty) == 0
						if canblock:
							p.state = CsBlock.new(p, hit as ST.AttInfo_Hit, !push)
							p.state.block_state = block_ty
							_inc_gauge.call(p, opp, hit.gauge, GAUGE_BLOCK)
						else:
							p.state = CsStun.new(p, hit as ST.AttInfo_Hit, !push)
							p.state.eff_pos = eff_pos
							_inc_gauge.call(p, opp, hit.gauge, GAUGE_HIT)
					ST.STUN_TY.PARRY:
						(p.state as CsParry).parried_nf = (hit as ST.AttInfo_Hit).stun_block
						_inc_gauge.call(p, opp, hit.gauge, GAUGE_PARRY)
					_:
						if hit.ty == ST.ATTACK_TY.HIGH_SUPER:
							var cin = ST.CinematicInfo.new()
							cin.is_p2 = opp.is_p2
							cin.show_opp = true
							cin.anim_name = "super_2_cinematic"
							cin.anim_name_opp = "opp/opp_super_2_cinematic"
							cin.n_frames = hit.n_cinematic_hit
							cin.move = hit
							game_state.cinematic(cin)
							p.pos = opp.pos + Vector2i(-500 if opp.action_is_p2 else 500, 0)
						else:
							var sto = p.state as _CsStunBase
							p.state = CsStun.new(p, hit as ST.AttInfo_Hit)
							p.state.eff_pos = eff_pos
							var dmg = (p.state as _CsStunBase).apply_scaling(sto, hit as ST.AttInfo_Hit)
							p.bar_health = maxi(p.bar_health - dmg, 0)
							_inc_gauge.call(p, opp, hit.gauge, GAUGE_HIT)
			
			o.freeze = maxi(o.freeze, hit.n_freeze)
		elif hit.ty == ST.ATTACK_TY.GRAB:
			if p.state.airborne:
				opp.state.att_processed = false
			else:
				if p.state.attack_ty == ST.ATTACK_TY.GRAB and counter_ty != ST.STUN_TY.PUNISH_COUNTER:
						p.state = CsGrabTech.new()
						opp.state = CsGrabTech.new()
						o.hit1 = null
						o.hit2 = null
				else:
					if p.state is CsStun:
						opp.state.att_processed = false
					else:
						p.state = CsGrabOpp.new(opp, hit as ST.AttInfo_Grab)
						p.bar_health = maxi(p.bar_health - hit.dmg, 0)
						var fd = (hit as ST.AttInfo_Grab).fix_dist
						if fd < 100000:
							if opp.action_is_p2: fd *= -1
							p.pos = opp.pos + Vector2i(fd, 0)
							p.state.push_wall = true

	if o.hit1 and o.hit2:
		if o.hit1.ty == ST.ATTACK_TY.CMD_GRAB:
			o.hit2 = null #cmd grab always win
		elif o.hit2.ty == ST.ATTACK_TY.CMD_GRAB:
			o.hit1 = null
		if o.hit1.ty == ST.ATTACK_TY.HIGH_SUPER:
			o.hit2 = null #super wins next
		elif o.hit2.ty == ST.ATTACK_TY.HIGH_SUPER:
			o.hit1 = null
		elif (o.hit1.ty & ST.ATTACK_TY._HIT_BIT) > 0 and (o.hit1.ty & ST.ATTACK_TY._HIT_BIT) > 0:
			pass #trade
		elif o.hit1.ty != o.hit2.ty:
			#hit wins over grab
			if (o.hit1.ty & ST.ATTACK_TY._GRAB_BIT) > 0:
				o.hit1 = null
			else:
				o.hit2 = null

	if o.hit1:
		apply_hit.call(p2, p1, o.hit1, o.push1, o.pos1)
	if o.hit2:
		apply_hit.call(p1, p2, o.hit2, o.push2, o.pos2)
	
	if o.freeze > 0:
		game_state.freeze(o.freeze)

static func _proc_push(game_state : GameState):
	var p1 = game_state.p1
	var p2 = game_state.p2
	
	var ww = game_state.wall
	
	if p1.pos.y < 0:
		p1.pos.y = 0
	if p2.pos.y < 0:
		p2.pos.y = 0
	
	var p2b1 = p1.bounded_pos - p1.pos
	var p2b2 = p2.bounded_pos - p2.pos
	
	var dp = (p2.bounded_pos - p1.bounded_pos).abs()
	var dx = CHARA_DIST - dp.x
	if dp.y != 0:
		var cr = false#(p1.state & ST.STATE_CROUCH_BIT) > 0 or (p2.state & ST.STATE_CROUCH_BIT) > 0
		var ht = CHARA_HALF_HEIGHT_CR if cr else CHARA_HALF_HEIGHT
		var dy = (dp.y - ht) * 2
		if dy > 0:
			dx -= (dy * CHARA_DIST) / ht
	var push = p1.state.push_wall or p2.state.push_wall
	if dx > 0:
		push = true
		var d = dx / (2 if p2.pos > p1.pos else -2)
		p1.pos.x -= d
		p1.bounded_pos.x -= d
		p2.pos.x += d
		p2.bounded_pos.x += d
		dp.x = CHARA_DIST
	
	var dpw = ww.x - p1.bounded_pos.x
	if dpw > 0:
		if push: p2.pos.x += dpw
		p1.pos.x += dpw
		if p1.pos.y > 0:
			p1.pos.x += 1
	dpw = ww.x - p2.bounded_pos.x
	if dpw > 0:
		if push: p1.pos.x += dpw
		p2.pos.x += dpw
		if p2.pos.y > 0:
			p2.pos.x += 1
	
	dpw = p1.bounded_pos.x - ww.y
	if dpw > 0:
		if push: p2.pos.x -= dpw
		p1.pos.x -= dpw
		if p1.pos.y > 0:
			p1.pos.x -= 1
	dpw = p2.bounded_pos.x - ww.y
	if dpw > 0:
		if push: p1.pos.x -= dpw
		p2.pos.x -= dpw
		if p2.pos.y > 0:
			p2.pos.x -= 1
	
	p1.bounded_pos = p1.pos + p2b1
	p2.bounded_pos = p2.pos + p2b2
	
	var cx = clampi((p1.bounded_pos.x + p2.bounded_pos.x) / 2, WALL_W, 10000 - WALL_W)
	game_state.wall = Vector2i(cx - WALL_W, cx + WALL_W)
	
	var sdp = p2.pos - p1.pos
	p1.dist_to_opp = sdp
	p2.dist_to_opp = -sdp
	
	return dp.x

static func _check_hit(p1 : PlayerState, p2 : PlayerState):
	var p1state = p1.state as _CsAttBase
	
	if not p1state and p1.summons.is_empty():
		return null
	
	var hurts : Array[Rect2i] = []
	for b in p2.boxes:
		if b.ty == ST.BOX_TY.HURT:
			hurts.push_back(b.get_rect(p2.action_is_p2))
	var dp = p1.pos - p2.pos
	
	if p1state and not p1state.att_processed:
		for b in p1.boxes:
			if b.ty == ST.BOX_TY.HIT || b.ty == ST.BOX_TY.HIT_SUPER || b.ty == ST.BOX_TY.GRAB:
				var b2 = Rect2i(b.get_rect(p1.action_is_p2))
				b2.position += dp
				for b3 in hurts:
					if b2.intersects(b3):
						p1state.att_processed = true
						return [p1state.query_hit(), true, p2.pos + b2.intersection(b3).get_center()]
	
	for sm in p1.summons:
		if sm.hit_cd > 0:
			continue
		dp = sm.pos - p2.pos
		for b in sm._info.boxes:
			if b.ty == ST.BOX_TY.HIT:
				var b2 = Rect2i(b.get_rect(p1.action_is_p2))
				b2.position += dp
				for b3 in hurts:
					if b2.intersects(b3):
						sm.on_hit()
						return [sm._info.att_info, sm.state_t < 3, p2.pos + b2.intersection(b3).get_center()]
	
	return null
