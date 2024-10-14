class_name BigText extends Control

@onready var base = $"base"
@onready var overlay = $"overlay"

@export var base_width = 0.0
@export var tar_width = 1.0

@export var text : String

@onready var w0 = -15 + 20.0 * base_width
@onready var w1 = -15 + 20.0 * tar_width

func _ready():
	base.text = text
	overlay.text = text.to_lower()
	set_anim_t(0)

func set_anim_t(f):
	var font = base.get("theme_override_fonts/font") as FontVariation
	font.spacing_glyph = lerp(w0, w1, f)
