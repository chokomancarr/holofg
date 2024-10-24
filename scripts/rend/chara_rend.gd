class_name CharaRend extends Node3D

const ANCHORS = ["_anchor_free", "_anchor_hip", "_anchor_hand_L", "_anchor_hand_R", "_anchor_leg_L", "_anchor_leg_R"]

static var insts = [ null, null ]

@export var is_p1 = true

@onready var mdl = get_child(0) as Node3D
@onready var arm = mdl.get_node("Armature") as Node3D
@onready var anim = mdl.get_node("AnimationPlayer") as AnimationPlayer
@onready var anim_ctrl = anim.get_node("CharaAnimPlayer") as CharaAnimPlayer

@onready var expr = %"CharaExpress" as CharaExpress
@onready var doodle = $"doodle" as AnimatedSprite3D
@onready var doodle_loop = $"doodle_loop" as AnimatedSprite3D
var access : CharaAccess

var summon_objs = {}

var anchors : Array[Node3D]
var cam_anchor : Node3D
var effects : EffectRend
var streaks : CharaStreaks

var overlay_mat : ShaderMaterial
var _overlay_shader = preload("res://chara_highlight.tres")

var _hit_txt_counter = preload("res://scenes/counter.tscn")
var hit_status_txt : TxtCounter

@onready var palette = %"palette" as CharaPalette

func _set_overlay(oo : Array, mat : Material):
	for o : Node in oo:
		if o is MeshInstance3D:
			o.material_overlay = mat
		_set_overlay(o.get_children(), mat)

func set_overlay_col(c : Color, f : float):
	overlay_mat.set_shader_parameter("color", [ c.r, c.g, c.b ])
	overlay_mat.set_shader_parameter("strength", c.a)
	overlay_mat.set_shader_parameter("fresnel", f)

func _ready():
	palette.apply_palette(0 if is_p1 else 1)
	
	insts[ 1 - int(is_p1) ] = self
	anchors.push_back(arm)
	var skel = arm.get_node("Skeleton3D") as Skeleton3D
	
	cam_anchor = skel.get_node("Camera") as BoneAttachment3D
	
	for s in ANCHORS:
		var anc = BoneAttachment3D.new()
		skel.add_child(anc)
		if skel.find_bone(s) > -1:
			anc.bone_name = s
		else:
			anc.bone_name = "CC_Base_BoneRoot"
		anchors.push_back(anc)
	
	overlay_mat = ShaderMaterial.new()
	overlay_mat.shader = _overlay_shader
	_set_overlay(get_children(), overlay_mat)
	set_overlay_col(Color.TRANSPARENT, 0.0)
	
	_ready2.call_deferred()

func _ready2():
	access = CharaAccess.new()
	add_child(access)
	
	if not is_p1:
		doodle.flip_h = true
		doodle.position.x *= -1
		doodle_loop.flip_h = true
		doodle_loop.position.x *= -1
	
		for c in get_children():
			_set_layer(c)

func _set_layer(c : Node):
	if c is VisualInstance3D:
		c.layers = c.layers << 5
	for c2 in c.get_children():
		_set_layer(c2)
 
func _init_effects(i):
	effects = EffectRend.new(i, self)
	
	streaks = CharaStreaks.new(i, self)
	mdl.add_child(streaks)

func _physics_process(dt):
	var gst = GameMaster.game_state
	if not gst:
		return
	var pst = gst.p1 if is_p1 else gst.p2
	var pss = pst.state
	
	if pss is _CsAttBase:
		expr.expr = CharaExpress.EXPR.ATTACK 
	elif pss is _CsStunBase:
		expr.expr = CharaExpress.EXPR.STUN
	else:
		expr.expr = CharaExpress.EXPR.IDLE
	
	if pss is _CsStunBase:
		if pss.counter_ty == ST.STUN_TY.COUNTER:
			if hit_status_txt != null:
				if hit_status_txt.uid != pss.counter_uid:
					hit_status_txt.free()
			if not hit_status_txt:
				hit_status_txt = _hit_txt_counter.instantiate() as TxtCounter
				hit_status_txt.init(pst, self)
				add_child(hit_status_txt)
				_set_layer(hit_status_txt)
	
	if access:
		access.step(pst, self)
	
	streaks.step(pst, self)

func _process(delta):
	var gst = GameMaster.game_state
	if not gst:
		return
	
	var pst = gst.p1 if is_p1 else gst.p2
	position.x = (pst.pos.x - 5000) * 0.002
	position.y = pst.pos.y * 0.002
	expr.p2 = pst.action_is_p2
	
	match gst.state:
		GameState.MATCH_STATE.INTRO:
			visible = is_p1 == (gst.countdown > 100)
			anim_ctrl.step(gst, pst, delta)
			if gst.countdown == 100:
				var fade = $"/root/main/fade_in"
				fade.reset()
				#fade.kill = true
		_:
			if gst.state == GameState.MATCH_STATE.PREGAME:
				if gst.countdown == 150 and not doodle.visible:
					doodle.visible = true
					doodle.play()
					doodle.animation_finished.connect(_hide_doodle)
					doodle_loop.visible = true
					doodle_loop.play()
			else:
				doodle_loop.stop()
				doodle_loop.visible = false
			
			var cinfo = gst.cinematic_info
			if cinfo:
				var is_opp = (gst.cinematic_is_p2 == is_p1)
				if is_opp and not cinfo.anim_name_opp:
					visible = false
				else:
					visible = true
					anim_ctrl.step_cinematic(cinfo.anim_name_opp if is_opp else cinfo.anim_name, gst.p2 if gst.cinematic_is_p2 else gst.p1, gst.cinematic_t)
			else:
				visible = true
				anim_ctrl.step(gst, pst, delta)
			
			for so in summon_objs.values():
				so[1] = false
			
			for sm in pst.summons:
				var k = sm.sm_hash
				if summon_objs.has(k):
					var o = summon_objs[k]
					o[0].state = sm
					o[1] = true
					
				else:
					summon_objs[k] = [ _gen_summon_scene(pst, is_p1, sm), true ]
			
			for so in summon_objs:
				var sv = summon_objs[so]
				if !sv[1]:
					sv[0].queue_free()
					summon_objs.erase(so)
			
			effects.process(pst, gst.state == GameState.MATCH_STATE.CINEMATIC)
			
			if pst.state is CsParry:
				if pst.state.anim_name == "parry_recovery":
					set_overlay_col(Color(Color.AQUA, (pst.state.NF_RECOVERY + pst.state.rec_df - 1.0 - pst.state.state_t) / pst.state.NF_RECOVERY), 1.0)
				else:
					set_overlay_col(Color.AQUA, 1.0)
			elif pst.state is CsTeleport:
				if pst.state.anim_name == "tp_startup":
					set_overlay_col(Color.AQUA, 1.0 - ((pst.state.state_t - 1.0) / CsTeleport.NF_TP))
				else:
					var f = minf((pst.state.state_t - CsTeleport.NF_TP - 2.0) / CsTeleport.NF_FWD, 1.0)
					set_overlay_col(Color(Color.AQUA, 1.0 - f), 1.0)
			else:
				set_overlay_col(Color.TRANSPARENT, 1.0)

func _gen_summon_scene(pst : PlayerState, p, sm : SummonState):
	var ps = load("res://chara_scenes/summons/sm_%d_%s.tscn" % [ pst._info._id, sm._info.scene ]) as PackedScene
	if not ps:
		print_debug("could not load scene '%s' for summon!" % sm._info.scene)
		return null
	var scn = ps.instantiate()
	scn.name = "summon_p%d_%d" % [ int(is_p1), sm.sm_hash ]
	(scn as SummonRend).state = sm
	get_parent().add_child(scn)
	_set_layer(scn)
	return scn

func attach_to_anchor(nd : Node, anchor : String):
	if anchor == "":
		anchors[0].add_child(nd)
	else:
		var par = ANCHORS.find("_anchor_" + anchor)
		if par > -1:
			anchors[par + 1].add_child(nd)

func _hide_doodle():
	doodle.visible = false

func set_rend_layers(rnd : VisualInstance3D):
	rnd.layers = 0b111110000000000
	if not is_p1:
		rnd.layers = rnd.layers << 5
