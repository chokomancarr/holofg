class_name GameCollider

const CHARA_DIST = 300
const CHARA_HALF_HEIGHT = 500
const CHARA_HALF_HEIGHT_CR = 300
const WALL_W = 2000

static func step(game_state : GameState):
	var p1 = game_state.p1
	var p2 = game_state.p2
	
	var dist = _proc_push(game_state)

	var o = {
		"hit1" : _check_hit(p1, p2) as ST._AttInfoBase,
		"hit2" : _check_hit(p2, p1) as ST._AttInfoBase,
		"freeze" : 0
	}
	#if hit1 or hit2:
		#if hit1:
			#if game_state.p1.state.query_stun() != ST.STUN_TY.PUNISH_COUNTER\
			#and game_state.p1.state.query_stun() != ST.STUN_TY.PUNISH_COUNTER:
				#game_state.p1.state = CsGrabTech.new()
				#game_state.p2.state = CsGrabTech.new()
				#return

	var apply_hit = func (p : PlayerState, opp : PlayerState, hit : ST._AttInfoBase, o):
		var counter_ty = p.state.query_stun()
		if (hit.ty & ST.ATTACK_TY._HIT_BIT) > 0:
			if p.state.airborne:
				p.state = CsStunAir.new(p, ST.STUN_AIR_TY.RESET if counter_ty == ST.STUN_TY.NORMAL else ST.STUN_AIR_TY.JUGGLE)
			else:
				match counter_ty:
					ST.STUN_TY.BLOCK:
						var block_ty = p.state.block_state
						var canblock = (hit.ty & ~block_ty) == 0
						if canblock:
							p.state = CsBlock.new(p, hit as ST.AttInfo_Hit)
							p.state.block_state = block_ty
							#o.freeze = maxi(o.freeze, 5)
							#return
						else:
							p.state = CsStun.new(p, hit as ST.AttInfo_Hit)
					ST.STUN_TY.PARRY:
						(p.state as CsParry).parried_nf = (hit as ST.AttInfo_Hit).stun_block
					_:
						p.state = CsStun.new(p, hit as ST.AttInfo_Hit)
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
					if true:
						p.state = CsGrabOpp.new(opp, hit as ST.AttInfo_Grab)
						var fd = (hit as ST.AttInfo_Grab).fix_dist
						if fd < 100000:
							if opp.action_is_p2: fd *= -1
							p.pos = opp.pos + Vector2i(fd, 0)
							p.state.push_wall = true

	if o.hit1:
		apply_hit.call(p2, p1, o.hit1, o)
	if o.hit2:
		apply_hit.call(p1, p2, o.hit2, o)
	
	if o.freeze > 0:
		game_state.freeze(o.freeze, true)

static func _proc_push(game_state : GameState):
	var p1 = game_state.p1
	var p2 = game_state.p2
	
	var ww = game_state.wall
	
	if p1.pos.y < 0:
		p1.pos.y = 0
	if p2.pos.y < 0:
		p2.pos.y = 0
	
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
		var d = dx * (0.5 if p2.pos > p1.pos else -0.5)
		p1.pos.x -= d
		p2.pos.x += d
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
	
	var cx = clampi((p1.bounded_pos.x + p2.bounded_pos.x) / 2, WALL_W, 10000 - WALL_W)
	game_state.wall = Vector2i(cx - WALL_W, cx + WALL_W)
	
	var sdp = p2.pos - p1.pos
	p1.dist_to_opp = sdp
	p2.dist_to_opp = -sdp
	
	return dp.x

static func _check_hit(p1 : PlayerState, p2 : PlayerState):
	var p1state = p1.state as _CsAttBase
	if not p1state:
		return null
	if p1state.att_processed:
		return null
	var hurts : Array[ST.BoxInfo] = []
	for b in p2.boxes:
		if b.ty == ST.BOX_TY.HURT:
			hurts.push_back(b)
	var dp = p1.pos - p2.pos
	for b in p1.boxes:
		if b.ty == ST.BOX_TY.HIT || b.ty == ST.BOX_TY.GRAB:
			var b2 = Rect2i(b.get_rect(p1.action_is_p2))
			b2.position += dp
			for b3 in hurts:
				if b2.intersects(b3.get_rect(p2.action_is_p2)):
					p1state.att_processed = true
					return p1state.query_hit()
	return null
