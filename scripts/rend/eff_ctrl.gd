class_name EffCtrl extends Node3D

@export var follow_rotation := true
var in_recovery : bool
var parts : Array[GPUParticles3D]
var sprites : Array[AnimatedSprite3D]
var pi : int

func _ready():
	if not follow_rotation:
		global_rotation = Vector3.ZERO
	
	parts.assign(get_children().filter(func (c): return c is GPUParticles3D))
	sprites.assign(get_children().filter(func (c): return c is AnimatedSprite3D))
	for s in sprites:
		s.play()
		s.animation_finished.connect(func ():
			s.queue_free()
		)

func _process(_dt):
	var pause = false
	if GameMaster.game_state.state == GameState.MATCH_STATE.ATT_FREEZE:
		pause = !(GameMaster.game_state.freeze_canbuffer & pi)
	
	for p in parts:
		p.process_mode = Node.PROCESS_MODE_DISABLED if pause else Node.PROCESS_MODE_INHERIT
		p.speed_scale = Engine.physics_ticks_per_second / 60.0
		p.emitting = not in_recovery
	
	for s in sprites:
		if s != null:
			s.speed_scale = 0 if pause else Engine.physics_ticks_per_second / 60.0
