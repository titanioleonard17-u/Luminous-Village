extends StaticBody2D

@export var door_path: NodePath # drag node Door instance di Inspector

var is_dragging: bool = false
var touch_index: int = -1
var last_hit_frame: int = -10
var door: Node = null

func _ready() -> void:
	if not door_path.is_empty():
		door = get_node(door_path)

func _physics_process(_delta: float) -> void:
	if door == null:
		return
	var current_frame: int = Engine.get_physics_frames()
	var is_hit: bool = (current_frame - last_hit_frame) <= 1
	if door.has_method("set_open"):
		door.set_open(is_hit)

func mark_hit() -> void:
	last_hit_frame = Engine.get_physics_frames()

func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)

# --- Rotate lewat sentuh/drag, sama kayak Mirror ---
func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_point_over(get_global_mouse_position()):
				is_dragging = true
			else:
				is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		_rotate_towards(get_global_mouse_position())

	if event is InputEventScreenTouch:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and _is_point_over(world_pos):
			is_dragging = true
			touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			is_dragging = false
			touch_index = -1

	if event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_rotate_towards(world_pos)

func _rotate_towards(world_pos: Vector2) -> void:
	var direction: Vector2 = world_pos - global_position
	rotation = direction.angle()

func _is_point_over(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) < 80.0
