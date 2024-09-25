class_name GameNet_Rollback extends _GameNetBase

var rb_state : GameState

var p1_inputs : RbPlayer
var p2_inputs : RbPlayer

func init():
	var lobby = OnlineLobby.lobby
	if not lobby or not lobby.p2:
		print_debug("lobby is not ready")
		return
	
	rb_state = GameMaster.game_state
	p1_inputs = RbPlayer.new()
	p2_inputs = RbPlayer.new()
	add_child(p1_inputs)
	add_child(p2_inputs)
	p1_inputs.init(lobby.p1.mp_id, lobby.p1.input_source)
	p2_inputs.init(lobby.p2.mp_id, lobby.p2.input_source)
	
	multiplayer.multiplayer_peer = OnlineLobby.rtc
	
	SyncManager.sync_started.connect(_on_sync_started)
	SyncManager.sync_stopped.connect(_on_sync_stopped)
	SyncManager.sync_lost.connect(_on_sync_lost)
	SyncManager.sync_regained.connect(_on_sync_regained)
	SyncManager.sync_error.connect(_on_sync_error)
	
	if lobby.is_p2:
		SyncManager.add_peer(lobby.p1.mp_id)
	else:
		SyncManager.add_peer(lobby.p2.mp_id)
	
	add_to_group("network_sync")

func start():
	SyncManager.start()

func get_game_state():
	return rb_state


func on_sync_started():
	print_debug("sync started")

func on_sync_stopped():
	pass

func on_sync_lost():
	pass

func on_sync_regained():
	pass

func on_sync_error():
	print_debug("fatal sync error")
	SyncManager.clear_peers()
	multiplayer.multiplayer_peer.close()

func network_process(_dict : Dictionary):
	_step_game_state(rb_state, p1_inputs.inputs, p2_inputs.inputs)

func _save_state() -> Dictionary:
	return { "gs": rb_state.clone() }

func _load_state(dict : Dictionary):
	rb_state = dict.gs.clone()

func _get_debug_text():
	return ""