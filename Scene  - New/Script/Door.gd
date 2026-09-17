extends StaticBody2D
@export var open_rotation_degrees: float = 45.0  # seberapa jauh dia membuka RELATIF dari posisi tertutup
@export var open_speed: float = 0.5
@export var required_triggers: int = 1  # berapa trigger yang harus aktif bareng biar pintu terbuka (set 1 kalau mau perilaku lama)

var is_open: bool = false
var closed_rotation: float = 0.0  # rotasi "tertutup" diambil dari posisi awal di editor
var active_triggers: Dictionary = {}  # menyimpan trigger mana saja yang sedang "menyala"

func _ready() -> void:
	closed_rotation = rotation_degrees  # simpan rotasi awal (misal 45°) sebagai acuan tertutup

# Dipanggil oleh setiap Trigger di tiap physics frame, melaporkan status hit-nya sendiri
func set_trigger_state(trigger: Node, is_hit: bool) -> void:
	if is_hit:
		active_triggers[trigger] = true
	else:
		active_triggers.erase(trigger)

	var should_open: bool = active_triggers.size() >= required_triggers
	_apply_open_state(should_open)

func _apply_open_state(should_open: bool) -> void:
	if should_open == is_open:
		return
	is_open = should_open
	var target: float = closed_rotation + open_rotation_degrees if is_open else closed_rotation
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", target, open_speed)	
