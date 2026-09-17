extends Camera2D

@export var LIMIT_X := 0
@export var LIMIT_Y := 0
@export var mirror_collision_layer := 2

var dragging := false
var last_mouse_position := Vector2.ZERO

func _ready():
	limit_left = -576 - LIMIT_X
	limit_right = 576 + LIMIT_X
	limit_top = -324 - LIMIT_Y
	limit_bottom = 324 + LIMIT_Y

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_mouse_over_mirror():
					dragging = false
					return

				dragging = true
				last_mouse_position = event.position
			else:
				dragging = false

	if event is InputEventMouseMotion and dragging:
		var mouse_delta = event.position - last_mouse_position
		var new_position = position - mouse_delta

		new_position.x = clamp(new_position.x, limit_left, limit_right)
		new_position.y = clamp(new_position.y, limit_top, limit_bottom)

		position = new_position
		last_mouse_position = event.position

func is_mouse_over_mirror() -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_point(query)

	for hit in result:
		var collider = hit.collider

		if collider.is_in_group("mirror"):
			return true

	return false
