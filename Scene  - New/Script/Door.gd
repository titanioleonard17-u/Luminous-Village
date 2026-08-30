extends StaticBody2D

@export var open_rotation_degrees: float = 90.0
@export var open_speed: float = 0.5

var is_open: bool = false

func set_open(should_open: bool) -> void:
	if should_open == is_open:
		return
	is_open = should_open
	var target: float = open_rotation_degrees if is_open else 0.0
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", target, open_speed)
