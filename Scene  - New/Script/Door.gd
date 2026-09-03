extends StaticBody2D
@export var open_rotation_degrees: float = 45.0  # seberapa jauh dia membuka RELATIF dari posisi tertutup
@export var open_speed: float = 0.5

var is_open: bool = false
var closed_rotation: float = 0.0  # rotasi "tertutup" diambil dari posisi awal di editor

func _ready() -> void:
	closed_rotation = rotation_degrees  # simpan rotasi awal (misal 45°) sebagai acuan tertutup

func set_open(should_open: bool) -> void:
	if should_open == is_open:
		return
	is_open = should_open
	var target: float = closed_rotation + open_rotation_degrees if is_open else closed_rotation
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", target, open_speed)
