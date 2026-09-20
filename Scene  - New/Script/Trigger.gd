extends StaticBody2D

@export var door_path: NodePath

@export var interact_radius: float = 100.0
@export var ball_ratio: float = 0.18
@export var facing_offset_degrees: float = 90.0

@export var min_tau: float = 0.05
@export var max_tau: float = 0.8
@export var response_curve: float = 0.15
@export var rotation_speed: float = 0.35

var is_interact_locked: bool = false
var is_dragging: bool = false
var touch_index: int = -1
var last_hit_frame: int = -10
var door: Node = null
var target_rotation: float = 0.0
var active_sensitivity: float = -1.0

var joystick_ui: JoystickUI
var touch_world_pos: Vector2 = Vector2.ZERO

var _blank_cursor: ImageTexture


func _ready() -> void:
	add_to_group("sensitivity_target")
	target_rotation = rotation

	if not door_path.is_empty():
		door = get_node(door_path)

	joystick_ui = JoystickUI.new()
	joystick_ui.ring_texture = preload("res://Asset/Art/UI Rotate.png")
	joystick_ui.top_level = true
	joystick_ui.z_index = 100
	joystick_ui.ring_display_radius = interact_radius
	joystick_ui.ball_display_radius = interact_radius * ball_ratio
	joystick_ui.global_position = global_position
	joystick_ui.visible = false
	add_child(joystick_ui)
	joystick_ui.set_angle(rotation + deg_to_rad(facing_offset_degrees))

	var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	_blank_cursor = ImageTexture.create_from_image(img)


func _physics_process(_delta: float) -> void:
	if door == null:
		return
	var current_frame: int = Engine.get_physics_frames()
	var is_hit: bool = (current_frame - last_hit_frame) <= 1
	if door.has_method("set_trigger_state"):
		door.set_trigger_state(self, is_hit)


func _input(event: InputEvent) -> void:
	if is_interact_locked:
		return

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

	if event is InputEventScreenTouch:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			if not is_dragging and _is_point_over(world_pos):
				touch_index = event.index
				touch_world_pos = world_pos
				_start_drag()
		else:
			if is_dragging and event.index == touch_index:
				touch_index = -1
				_end_drag()

	if event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		touch_world_pos = get_global_transform_with_canvas().affine_inverse() * event.position


func mark_hit() -> void:
	last_hit_frame = Engine.get_physics_frames()


func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)


func _process(delta: float) -> void:
	if not is_dragging:
		return

	var world_pos: Vector2
	if touch_index != -1:
		world_pos = touch_world_pos
	else:
		world_pos = get_global_mouse_position()

	_set_target(world_pos)
	_apply_rotation(delta)


func _start_drag() -> void:
	is_dragging = true
	joystick_ui.global_position = global_position
	joystick_ui.visible = true

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.set_custom_mouse_cursor(_blank_cursor)


func _end_drag() -> void:
	is_dragging = false
	joystick_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.set_custom_mouse_cursor(null)

	var screen_pos: Vector2 = get_viewport().get_screen_transform() * get_viewport().canvas_transform * global_position
	Input.warp_mouse(screen_pos)


func set_interact_locked(value: bool) -> void:
	is_interact_locked = value


func _set_target(world_pos: Vector2) -> void:
	var direction: Vector2 = world_pos - global_position
	var mouse_angle: float = direction.angle()
	target_rotation = mouse_angle - deg_to_rad(facing_offset_degrees)


func _apply_rotation(delta: float) -> void:
	var t: float = rotation_speed
	if active_sensitivity >= 0.0:
		t = active_sensitivity
	t = clamp(t, 0.0, 1.0)

	if t <= 0.0:
		return

	var t_curved: float = pow(t, response_curve)
	var tau: float = lerp(max_tau, min_tau, t_curved)

	var weight: float = 1.0 - exp(-delta / tau)
	rotation = lerp_angle(rotation, target_rotation, weight)

	var remaining: float = abs(wrapf(target_rotation - rotation, -PI, PI))
	if remaining < deg_to_rad(1.0):
		rotation = target_rotation

	joystick_ui.set_angle(rotation + deg_to_rad(facing_offset_degrees))


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


func set_sensitivity(raw_value: float, raw_max: float) -> void:
	if raw_max <= 0.0:
		active_sensitivity = 0.0
		return
	active_sensitivity = clamp(raw_value / raw_max, 0.0, 1.0)
