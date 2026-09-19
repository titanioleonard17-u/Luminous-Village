extends StaticBody2D

signal value_changed(value: float)

@export var track_length: float = 300.0   # panjang jalur drag (px), samakan dgn tinggi track visual
@export var min_value: float = 10.0
@export var max_value: float = 100.0
@export var default_value: float = 55.0
@export var invert: bool = true           # true = tarik ke bawah = nilai naik

# Isi ini di Inspector dengan node Mirror yang mau dikontrol (drag node Mirror ke sini),
# atau kalau Mirror di-spawn dinamis, panggil set_mirror_target() dari Mirror_spawner.
@export var mirror_target_path: NodePath
var mirror_target: Node = null

var is_dragging: bool = false
var touch_index: int = -1
var current_value: float = 0.5

@onready var handle: Sprite2D = $Handle

func _ready() -> void:
	current_value = default_value
	_update_handle_position()

	if mirror_target_path != NodePath(""):
		mirror_target = get_node_or_null(mirror_target_path)

	_apply_sensitivity_to_mirror()

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not is_dragging and _is_point_over(get_global_mouse_position()):
					_start_drag()
			else:
				if is_dragging:
					_end_drag()

	if event is InputEventMouseMotion and is_dragging:
		_drag_to(get_global_mouse_position())

	if event is InputEventScreenTouch:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			if not is_dragging and _is_point_over(world_pos):
				touch_index = event.index
				_start_drag()
		else:
			if is_dragging and event.index == touch_index:
				touch_index = -1
				_end_drag()

	if event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_drag_to(world_pos)

func _start_drag() -> void:
	is_dragging = true
	print("Slider: start drag")

func _end_drag() -> void:
	is_dragging = false
	print("Slider: end drag, final value = ", current_value)

func _drag_to(world_pos: Vector2) -> void:
	var local_y: float = world_pos.y - global_position.y

	var half: float = track_length * 0.5
	local_y = clamp(local_y, -half, half)

	var t: float = (local_y + half) / track_length
	if not invert:
		t = 1.0 - t

	current_value = lerp(min_value, max_value, t)
	_update_handle_position()
	value_changed.emit(current_value)
	_apply_sensitivity_to_mirror()
	print("Sensitivity value: ", current_value)

func _apply_sensitivity_to_mirror() -> void:
	if mirror_target != null and mirror_target.has_method("set_sensitivity"):
		mirror_target.set_sensitivity(current_value, max_value)

func _update_handle_position() -> void:
	var half: float = track_length * 0.5
	var t: float = (current_value - min_value) / (max_value - min_value)
	if not invert:
		t = 1.0 - t
	var local_y: float = lerp(-half, half, t)
	handle.position.y = local_y

func _is_point_over(world_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_bodies = true
	var result = space_state.intersect_point(query)
	for hit in result:
		if hit.collider == self:
			return true
	return false

func get_value() -> float:
	return current_value

func set_value(v: float) -> void:
	current_value = clamp(v, min_value, max_value)
	_update_handle_position()
	_apply_sensitivity_to_mirror()

# Dipanggil dari Mirror_spawner kalau Mirror di-spawn dinamis setelah slider sudah ada di scene
func set_mirror_target(target: Node) -> void:
	mirror_target = target
	_apply_sensitivity_to_mirror()
