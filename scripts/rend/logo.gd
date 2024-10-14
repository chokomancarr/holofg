extends AnimatedSprite2D

var wait = 1.0
var done = 0.0

func _ready():
	animation_finished.connect(_next_anim)

func _next_anim():
	play("end_loop")
	done = 1.5

func _process(dt):
	if wait > 0:
		wait -= dt
		if wait <= 0:
			play("default")
	if done > 0:
		done -= dt
		modulate.a = done
		if done <= 0:
			await get_tree().create_timer(1.0).timeout
			SceneMan.load_scene(SceneMan.MAIN_MENU)
