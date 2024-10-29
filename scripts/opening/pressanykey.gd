extends Node

@onready var ui_press = $"press_any_key"

func _ready():
	InputMan.default_device = await InputMan.wait_for_any_device()
	#ui_press.visible = false
	#await get_tree().create_timer(0.5).timeout
	ui_press.text = "connecting to server..."
	var ok = await OnlineLobby.init("user_" + str(randi_range(1000, 9999)))
	if ok:
		OnlineLobby.start_polling_loop()
	SceneMan.load_scene(SceneMan.MAIN_MENU)
