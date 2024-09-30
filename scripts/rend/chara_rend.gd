class_name CharaRend extends Node3D

static var insts = [ null, null ]

@export var is_p1 = true

@onready var mdl = get_child(0) as Node3D
@onready var arm = mdl.get_node("Armature") as Node3D
@onready var anim = mdl.get_node("AnimationPlayer") as AnimationPlayer
@onready var anim_ctrl = anim.get_node("anim_player") as CharaAnimPlayer

var summon_objs = {}

var anchors : Array[Node3D]
var cam_anchor : Node3D
var effects : EffectRend

var overlay_mat : ShaderMaterial
var _overlay_shader = preload("res://chara_highlight.tres")

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
	insts[ 1 if is_p1 else 2 ] = self
	anchors.push_back(arm)
	var skel = arm.get_node("Skeleton3D") as Skeleton3D
	
	var anc = BoneAttachment3D.new()
	skel.add_child(anc)
	anc.bone_name = "_anchor_camera"
	anchors.push_back(anc)
	
	for s in ["_anchor_hip"]:#, "_anchor_hand_L", "_anchor_hand_R", "_anchor_leg_L", "_anchor_leg_R"]:
		anc = BoneAttachment3D.new()
		skel.add_child(anc)
		anc.bone_name = s
		anchors.push_back(anc)
	
	overlay_mat = ShaderMaterial.new()
	overlay_mat.shader = _overlay_shader
	_set_overlay(get_children(), overlay_mat)
 
func _init_effects(i):
	effects = EffectRend.new(i, self)

func _process(delta):
	var gst = GameMaster.game_state
	if not gst:
		return
	
	var pst = gst.p1 if is_p1 else gst.p2
	position.x = (pst.pos.x - 5000) * 0.002
	position.y = pst.pos.y * 0.002
	
	arm.rotation.y = -PI / 2 if pst.action_is_p2 else PI / 2
	
	var cinfo = gst.cinematic_info
	if cinfo:
		var is_opp = (gst.cinematic_info.is_p2 == is_p1)
		if is_opp and not cinfo.show_opp:
			visible = false
		else:
			visible = true
			anim_ctrl.step_cinematic(cinfo.anim_name_opp if is_opp else cinfo.anim_name, gst.p2 if cinfo.is_p2 else gst.p1, gst.cinematic_t)
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
	
	effects.process(pst)
	
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
	return scn
