extends Node3D

@export var closed_position: Vector3 = Vector3.ZERO
@export var open_offset: Vector3 = Vector3(0, 3, 0)
@export var move_duration: float = 0.5

var is_open: bool = false
var current_tween: Tween

func _ready():
	closed_position = position

func set_door_state(should_open: bool):
	if should_open == is_open:
		return  # sudah di state itu, gak perlu tween lagi
	is_open = should_open

	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	var target = closed_position + open_offset if should_open else closed_position
	current_tween.tween_property(self, "position", target, move_duration)
