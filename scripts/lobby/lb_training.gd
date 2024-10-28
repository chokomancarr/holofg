extends Node

@onready var lobby_rend : LobbyRend = $"lobby_rend"

func _ready():
	_ready2.call_deferred()

func _ready2():
	lobby_rend.init()
	var input = await InputMan.get_default_input()
	
	if len(InputMan.available_devices) > 1:
		await lobby_rend.setcam(lobby_rend.CPOS_INPUTSEL)
		await lobby_rend.sel_input_p(false)
	else:
		lobby_rend.set_input_p(false, input)
	
	lobby_rend.set_input_p(true, input, false)
	
	await lobby_rend.setcam(lobby_rend.CPOS_CHARASEL)
	
	await lobby_rend.sel_chara_p(false)
	await lobby_rend.sel_chara_p(true)
	
	await get_tree().create_timer(1.0).timeout
	lobby_rend.start_vs_screen()
