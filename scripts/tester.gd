extends Node

@onready var usrnm = "user_" + str(randi_range(1111, 9999))
@onready var logger = $"%dbg" as Label

func _ready():
	($"Control/vb/usrnm" as Label).text = usrnm
	($"Control/vb/hb/clt/Button" as Button).pressed.connect(_on_make_srv)

	run.call_deferred()

func run():
	OnlineLobby.connect_to_mm_server(8000, func (s):
		logger.text = s + "\n" + logger.text
		print_debug(s)
	)
	#var sock = PacketPeerUDP.new()
	#sock.bind(8000)
	#print_debug("STUN output: ", await NetUtil.request_stun(sock))
	#NetUtil.mm_connect(usrnm, func (sock : PacketPeerUDP):
		#sock.put_packet(("hello from godot " + usrnm + "!").to_utf8_buffer())
		#print_debug("connected!")
	#)

func _on_make_srv():
	logger.text += "\ncreating lobby..."
	NetUtil.mm_request("ty=host&name=%s" % usrnm, func (s):
		logger.text += "\n" + s
		if s:
			var res = JSON.parse_string(s)
			if res.ok:
				$"Control/vb/hb/srv/code".text += res.lobby_id
	)
