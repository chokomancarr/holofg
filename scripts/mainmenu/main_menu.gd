extends Node

@onready var layers = [
	$"layer1",
	$"layer2"
]
@onready var splashes = [
	$"layer1/menu1", 
	$"layer1/menu2", 
	$"layer1/menu3", 
	$"layer1/menu4"
]
var layer = 1
var seld = -1:
	set(i):
		splashes[seld].visible = false
		seld = i
		splashes[seld].visible = true

func _ready():
	seld = 0
	#
	InputMan.default_device = InputMan.available_devices[0]
	
	$"%serv_make".pressed.connect(_on_make_lobby)
	$"%serv_join".pressed.connect(_on_join_lobby)

func _on_make_lobby():
	assert(OnlineLobby.rtc)
	var lobby = await OnlineLobby.create()
	if lobby:
		SceneMan.load_scene(SceneMan.LOBBY_ONLINE)

func _on_join_lobby():
	assert(OnlineLobby.rtc)
	var e = {}
	var lobby = await OnlineLobby.join($"%lobby_code".text.to_upper(), e)
	if lobby:
		SceneMan.load_scene(SceneMan.LOBBY_ONLINE)
	else:
		AlertMan.show(e.msg)

const NMS = [ "TRAINING", "OFFLINE", "ONLINE", "SETTINGS" ]
func open_layer2():
	layer = 2
	layers[1].visible = true
	layers[1].get_node("title").text = NMS[seld]
	layers[1].get_node(str(seld)).visible = true

func close_layer2():
	layers[1].get_node(str(seld)).visible = false
	layers[1].visible = false
	layer = 1

func _input(e: InputEvent):
	match layer:
		1:
			if not AlertMan.showing:
				var conf = false
				if e is InputEventMouseMotion:
					seld = clampi(floori(e.position.x / 250), 0, 4)
				elif e is InputEventMouseButton:
					if e.button_index == 1 and e.pressed:
						conf = true
						get_viewport().set_input_as_handled()
				elif InputMan.default_device:
					if InputMan.default_device.if_bt(e, KEY_A, JOY_BUTTON_DPAD_LEFT) and seld > 0:
						seld -= 1
					elif InputMan.default_device.if_bt(e, KEY_D, JOY_BUTTON_DPAD_RIGHT) and seld < 3:
						seld += 1
					elif InputMan.default_device.if_bt(e, KEY_F, JOY_BUTTON_B):
						conf = true
				
				if conf:
					match seld:
						0:
							SceneMan.load_scene(SceneMan.LOBBY_TRAIN)
						2:
							if OnlineLobby.state == OnlineLobby.STATE.NO_INIT:
								AlertMan.show("Not connected to server!")
							else:
								open_layer2()
						_:
							pass
		_:
			pass

func _unhandled_input(e: InputEvent):
	match layer:
		2:
			if InputMan.default_device.if_bt(e, KEY_ESCAPE, JOY_BUTTON_A):
				close_layer2()
		_:
			pass
