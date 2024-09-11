class_name GameCollider

const CHARA_DIST = 300
const CHARA_HALF_HEIGHT = 500
const CHARA_HALF_HEIGHT_CR = 300
const WALL_W = 2000

static func step(game_state : GameState):
	var dist = _proc_push(game_state)

	var hit1 = _check_hit(game_state.p1, game_state.p2)
	var hit2 = _check_hit(game_state.p2, game_state.p1)

	if hit1:
		game_state.p2.on_hit(hit1, dist)
		game_state.freeze(10, true)
	if hit2:
		game_state.p1.on_hit(hit2, dist)
		game_state.freeze(10, true)

static func _proc_push(game_state : GameState):
	var p1 = game_state.p1
	var p2 = game_state.p2
	
	var ww = game_state.wall
	
	if p1.pos.y < 0:
		p1.pos.y = 0
	if p2.pos.y < 0:
		p2.pos.y = 0
	
	var dp = (p2.pos - p1.pos).abs()
	var dx = CHARA_DIST - dp.x
	if dp.y != 0:
		var cr = false#(p1.state & ST.STATE_CROUCH_BIT) > 0 or (p2.state & ST.STATE_CROUCH_BIT) > 0
		var ht = CHARA_HALF_HEIGHT_CR if cr else CHARA_HALF_HEIGHT
		var dy = (dp.y - ht) * 2
		if dy > 0:
			dx -= (dy * CHARA_DIST) / ht
	var push = false
	if dx > 0:
		push = true
		var d = dx * (0.5 if p2.pos > p1.pos else -0.5)
		p1.pos.x -= d
		p2.pos.x += d
		dp.x = CHARA_DIST
	
	if p1.pos.x < ww.x:
		if push: p2.pos.x += ww.x - p1.pos.x
		p1.pos.x = ww.x
		if p1.pos.y > 0:
			p1.pos.x += 1
	if p2.pos.x < ww.x:
		if push: p1.pos.x += ww.x - p2.pos.x
		p2.pos.x = ww.x
		if p2.pos.y > 0:
			p2.pos.x += 1
	
	if p1.pos.x > ww.y:
		if push: p2.pos.x += ww.y - p1.pos.x
		p1.pos.x = ww.y
		if p1.pos.y > 0:
			p1.pos.x -= 1
	if p2.pos.x > ww.y:
		if push: p1.pos.x += ww.y - p2.pos.x
		p2.pos.x = ww.y
		if p2.pos.y > 0:
			p2.pos.x -= 1
	
	var cx = clampi((p1.pos.x + p2.pos.x) / 2, WALL_W, 10000 - WALL_W)
	game_state.wall = Vector2i(cx - WALL_W, cx + WALL_W)
	
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
		if b.ty == ST.BOX_TY.HIT:
			var b2 = Rect2i(b.rect)
			b2.position += dp
			for b3 in hurts:
				if b2.intersects(b3.rect):
					p1state.att_processed = true
					return p1state.query_hit()
	return null
