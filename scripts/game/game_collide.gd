class_name GameCollider

const CHARA_DIST = 300
const CHARA_HALF_HEIGHT = 500
const CHARA_HALF_HEIGHT_CR = 300
const WALL_W = 1500

const GAUGE_BLOCK = [5, 3]
const GAUGE_HIT = [10, 7]
const GAUGE_PARRY = [5, 15]

static func step(game_state : GameState):
	var p1 = game_state.p1
	var p2 = game_state.p2
	
	var dist = _proc_push(game_state)

	_check_clash(p1, p2)
	_check_clash(p2, p1)

	var o = {
		"hits": [
			_check_hit(p1, p2),
			_check_hit(p2, p1)
		],
		"freeze" : 0
	}
	var ty1 = o.hits[0].hit.ty if o.hits[0] else 0
	var ty2 = o.hits[1].hit.ty if o.hits[1] else 0

	if ty1 and ty2:
		var prio1 = AttInfo.TY_PRIO[ty1]
		var prio2 = AttInfo.TY_PRIO[ty2]
		if prio1 > prio2:
			o.hits[1] = null
		elif prio1 < prio2:
			o.hits[0] = null
		else:
			if (ty1 & AttInfo.TY._GRAB_BIT) > 0 or ty1 >= AttInfo.TY._SUPER_1_BIT: #only normal hits can trade
				o.hits[roundi(randf())] = null #we dont know which one hits first, so gacha
	
	var move2 = p2.state.move if (o.hits[1] and not o.hits[1].isproj) else null
	if o.hits[0]:
		apply_hit.call(game_state, p2, p1, null if o.hits[0].isproj else p1.state.move, o, 0)
	if o.hits[1]:
		apply_hit.call(game_state, p1, p2, move2, o, 1)
	
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
	if dx > 0 and p1.state.push_opp and p2.state.push_opp:
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

static func _check_clash(p1 : PlayerState, p2 : PlayerState):
	if p1.summons.is_empty() or p2.summons.is_empty():
		return
	
	var htb1 = p1.summons.map(func (sm):
		if sm.hit_cd == 0:
			return sm._info.boxes.filter(func (b):
				return b.ty != ST.BOX_TY.CLASH
			).map(func (b):
				return Rect2i(b.get_rect(sm.is_p2))
			)
		else:
			return []
	)
	var clb2 = p2.summons.map(func (sm):
		return sm._info.boxes.filter(func (b):
			return b.ty == ST.BOX_TY.CLASH
		).map(func (b):
			return Rect2i(b.get_rect(sm.is_p2))
		)
	)
	
	for i in len(htb1):
		var sm1 = p1.summons[i]
		for j in len(clb2):
			var sm2 = p2.summons[j]
			var dp = sm2.pos - sm1.pos
			
			for _hb in htb1[i]:
				var hb = Rect2i(_hb)
				hb.position += dp
				if clb2[j].any(func (cb):
					return hb.intersects(cb)
				):
					sm1.on_hit()
					sm2.on_hit()

static func _check_hit(p1 : PlayerState, p2 : PlayerState):
	var p1state = p1.state as _CsAttBase
	
	if not p1state and p1.summons.is_empty():
		return null
	
	var hurts = []
	for b in p2.boxes:
		if b.ty == ST.BOX_TY.HURT:
			hurts.push_back([b.get_rect(p2.action_is_p2), b.flags])
	var dp = p1.pos - p2.pos
	
	if p1state and not p1state.att_processed:
		for b in p1.boxes:
			if b.ty == ST.BOX_TY.HIT || b.ty == ST.BOX_TY.GRAB:
				var b2 = Rect2i(b.get_rect(p1.action_is_p2))
				b2.position += dp
				for b3 in hurts:
					if (b.flags & b3[1]) > 0:
						if b2.intersects(b3[0]):
							p1state.att_processed = true
							return {
								"isproj": false,
								"hit": p1state.query_hit(),
								"push": true,
								"pos": p2.pos + b2.intersection(b3[0]).get_center()
							}
	
	for sm in p1.summons:
		if sm.hit_cd > 0:
			continue
		dp = sm.pos - p2.pos
		for b in sm._info.boxes:
			if b.ty == ST.BOX_TY.HIT:
				var b2 = Rect2i(b.get_rect(p1.action_is_p2))
				b2.position += dp
				for b3 in hurts:
					if b2.intersects(b3[0]):
						sm.on_hit()
						return {
							"isproj": true,
							"hit": sm._info.att_info,
							"push": sm.state_t < 3,
							"pos": p2.pos + b2.intersection(b3[0]).get_center()
						}
	
	return null

static func apply_hit(gst : GameState, p : PlayerState, opp : PlayerState, move : MoveInfo, o, j):
	var oj = o.hits[j]
	var hit : AttInfo = oj.hit
	var push : bool = oj.push
	var eff_pos : Vector2i = oj.pos
	
	var connd = false
	
	var _inc_gauge = func (p : PlayerState, opp : PlayerState, inc : int, ratio : Array):
			opp.bar_super += (inc * ratio[0]) / 10
			p.bar_super += (inc * ratio[1]) / 10
	
	var counter_ty = p.state.query_stun()
	var block_ty = p.state.block_state
	if hit.box_ty == ST.BOX_TY.HIT:
		if counter_ty == ST.STUN_TY.PARRY:
			(p.state as CsParry).parried_nf = hit.stun_block
			_inc_gauge.call(p, opp, hit.gauge, GAUGE_PARRY)
		elif counter_ty == ST.STUN_TY.BLOCK and not ((hit.ty & 0x11) & ~block_ty):
			p.state = CsBlock.new(p, hit, block_ty, !push)
			_inc_gauge.call(p, opp, hit.gauge, GAUGE_BLOCK)
		else:
			_inc_gauge.call(p, opp, hit.gauge, GAUGE_HIT)
			connd = true
			
			var airty = hit.force_air
			
			if move and move.move_connd_opp: #use custom animation
				p.state = CsOppAnim.new(opp, move.move_connd_opp)
				p.pos.y = 0
			else:
				if not airty:
					if p.state.airborne:
						var sto = p.state as _CsStunBase
						if (counter_ty != ST.STUN_TY.NORMAL) or (sto is CsStunAir and sto.ty == ST.STUN_AIR_TY.JUGGLE):
							airty = ST.STUN_AIR_TY.JUGGLE
						else:
							airty = ST.STUN_AIR_TY.RESET
			
				var hh = hit as AttInfo.Hit
				match hh.knock_ty:
					ST.KNOCK_TY.KNOCKDOWN, ST.KNOCK_TY.HARD_KNOCKDOWN:
						p.state = CsKnock.new(p, hh)
					_:
						if airty:
							p.state = CsStunAir.new(p, airty)
						else:
							var standing = p.state.standing if (p.state is CsIdle or p.state is CsStun) else true
							p.state = CsStun.new(p, hh, false, standing)
				
				p.state.eff_pos = eff_pos
		
		o.freeze = maxi(o.freeze, hit.n_freeze)
	
	else: #is grab
		if p.state.attack_ty == AttInfo.TY.GRAB and counter_ty != ST.STUN_TY.PUNISH_COUNTER:
				p.state = CsGrabTech.new()
				opp.state = CsGrabTech.new()
				o.hits = [ null, null ]
		else:
			connd = true
			p.state = CsOppAnim.new(opp, opp.state.move.move_connd_opp)
			p.bar_health = maxi(p.bar_health - hit.dmg, 0)
			p.pos = opp.pos + Vector2i(-500 if opp.action_is_p2 else 500, 0)
			p.state.push_wall = true

	if connd:
		if opp.state is _CsAttBase:
			opp.state.att_connected = true
		if move:
			if move.cine_hit:
				opp.state = CsSuperEnd.new(opp, move.move_connd, false)
				p.state = CsSuperEnd.new(p, move.move_connd_opp, true)
				gst.cinematic(move.cine_hit, j == 1)
				o.freeze = 0
			elif move.move_connd:
				opp.state.move = move.move_connd
				opp.state.on_move_connected()
	
	if p.state is _CsStunBase:
		p.state.counter_ty = counter_ty
		p.state.counter_uid = gst.hit_uid_counter
		gst.hit_uid_counter += 1
