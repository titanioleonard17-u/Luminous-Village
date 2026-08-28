extends Node3D

@export var open_position: Vector3 = Vector3(0, 3, 0)
@export var open_duration: float = 1.0

var is_open: bool = false

func open_door():
	if is_open:
		return
	is_open = true
	var tween = create_tween()
	tween.tween_property(self, "position", position + open_position, open_duration)
