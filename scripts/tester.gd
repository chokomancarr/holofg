extends Node

@onready var usrnm = "user_" + str(randi_range(1111, 9999))
@onready var logger = $"Control/hb/dbg" as Label

func _ready():
	($"Control/usrnm" as Label).text = usrnm
	($"Control/hb/clt/Button" as Button).pressed.connect(_on_make_srv)

	run.call_deferred()

func run():
	var sock = PacketPeerUDP.new()
	sock.bind(8000)
	print_debug("STUN output: ", await NetUtil.request_stun(sock))
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
				$"Control/hb/srv/code".text += res.lobby_id
	)
