extends Control

@onready var time = %"game_ui_time"
@onready var hpbar_p1 = %"game_ui_hp_p1" as Range
@onready var hpbar_p2 = %"game_ui_hp_p2" as Range
@onready var spbars_p1 = [
	%"game_ui_sp1_p1", %"game_ui_sp2_p1", %"game_ui_sp3_p1"
] as Array[Range]
@onready var spbars_p2 = [
	%"game_ui_sp1_p2", %"game_ui_sp2_p2", %"game_ui_sp3_p2"
] as Array[Range]

@onready var netinfo : Control = $"/root/main/ui/top_cc/vb/hb0"
@onready var debug_info = %"game_ui_debug_info" as Label

var _next_nettinfo_upd = 0
func _ready():
	call_deferred("post_rdy")

func post_rdy():
	if not GameMaster.net_master is GameNet_Rollback:
		netinfo.modulate = Color.TRANSPARENT

func _physics_process(_dt):
	if GameMaster.net_master is GameNet_Rollback:
		_next_nettinfo_upd -= 1
		if _next_nettinfo_upd < 0:
			_next_nettinfo_upd = 30
			
			var peer = SyncManager.peers.values()[0] as SyncManager.Peer
			netinfo.get_node("ping").text = "P: " + str(peer.rtt)
			netinfo.get_node("rollback").text = "R: " + str(SyncManager.max_performed_rollback_ticks)
			netinfo.get_node("loss").text = "L: idk"
			
			SyncManager.max_performed_rollback_ticks = 0

func _process(dt):
	var gst = GameMaster.game_state as GameState
	if gst:
		if gst.countdown > -1:
			time.text = str(gst.countdown / 60).pad_zeros(2)
		else:
			time.text = "∞"
		hpbar_p1.value = gst.p1.bar_health
		hpbar_p1.max_value = gst.p1._info.max_health
		hpbar_p2.value = gst.p2.bar_health
		hpbar_p2.max_value = gst.p2._info.max_health
		
		for i in range(3):
			spbars_p1[i].value = gst.p1.bar_super - i * 100
			spbars_p2[i].value = gst.p2.bar_super - i * 100
	
	var upd_hit_stat = func (p : _CsBase, i, j):
		if p is _CsStunBase:
			get_node("cen_cc/gc/dmg%d" % i).text = "%d (%d)" % [ p.last_dmg, p.total_dmg ]
			get_node("cen_cc/gc/scl%d" % i).text = "%d%%" % (p.combo_scaling / 100)
			#get_node("cen_cc/gc/ty%d" % i).text = ST.ATTACK_TY.find_key(p.last_att_ty)
		elif p is _CsAttBase:
			if p.attack_ty != ST.ATTACK_TY.NONE:
				get_node("cen_cc/gc/ty%d" % j).text = ST.ATTACK_TY.find_key(p.attack_ty)
	
	upd_hit_stat.call(gst.p1.state, 2, 1)
	upd_hit_stat.call(gst.p2.state, 1, 2)
	
	debug_info.text = "%.1f game_speed\n%d frame_rate\n%s\n%s" % \
		[ GameMaster.game_speed_scale, roundi(1.0 / dt), GameMaster.game_state._get_debug_text(), GameMaster.net_master._get_debug_text() ]
