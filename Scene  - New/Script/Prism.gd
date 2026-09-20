extends StaticBody2D

## Sudut sisi pertama segitiga (derajat), diukur dari sumbu X (kanan).
## Kalau arah keluar cahayanya nggak pas sama sprite, geser nilai ini.
@export_range(-180, 180, 1) var forward_offset_deg: float = 0.0
@export var facing_offset_degrees: float = 90.0   # <-- TAMBAHAN
@export var interact_radius: float = 100.0
@export var ball_ratio: float = 0.18

@export var min_tau: float = 0.05
@export var max_tau: float = 0.8
@export var response_curve: float = 0.15
@export var rotation_speed: float = 0.35

var is_step_guide_active: bool = false
var is_dragging: bool = false
var touch_index: int = -1
var target_rotation: float = 0.0
var active_sensitivity: float = -1.0

var joystick_ui: JoystickUI
var touch_world_pos: Vector2 = Vector2.ZERO

var _blank_cursor: ImageTexture


func _ready() -> void:
	add_to_group("prism")
	add_to_group("sensitivity_target")
	target_rotation = rotation

	joystick_ui = JoystickUI.new()
	joystick_ui.ring_texture = preload("res://Asset/Art/UI Rotate.png")
	joystick_ui.top_level = true
	joystick_ui.z_index = 100
	joystick_ui.ring_display_radius = interact_radius
	joystick_ui.ball_display_radius = interact_radius * ball_ratio
	joystick_ui.global_position = global_position
	joystick_ui.visible = false
	add_child(joystick_ui)
	joystick_ui.set_angle(rotation)

	var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	_blank_cursor = ImageTexture.create_from_image(img)


func _input(event: InputEvent) -> void:
	if is_step_guide_active:
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

	var screen_pos: Vector2 = get_viewport().get_screen_transform() * global_position
	Input.warp_mouse(screen_pos)


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

func set_step_guide_status(value: bool) -> void:
	is_step_guide_active = value

func set_sensitivity(raw_value: float, raw_max: float) -> void:
	if raw_max <= 0.0:
		active_sensitivity = 0.0
		return
	active_sensitivity = clamp(raw_value / raw_max, 0.0, 1.0)


## Menghitung arah normal (mengarah keluar) dari 3 sisi segitiga, berdasar
## rotasi objek + forward_offset_deg. Segitiga dianggap simetris, jadi
## 3 sisinya dianggap berjarak 120° satu sama lain.
func _get_face_normals() -> Array:
	var base_angle: float = deg_to_rad(forward_offset_deg) + global_rotation
	var normals: Array = []
	for i in range(3):
		normals.append(Vector2.from_angle(base_angle + deg_to_rad(120.0 * i)))
	return normals


func get_reflect_normal() -> Vector2:
	return _get_face_normals()[0]


func get_split_origin() -> Vector2:
	return global_position


func get_split_directions(_incoming_dir: Vector2, _hit_normal: Vector2) -> Array:
	var normals: Array = _get_face_normals()
	return [normals[1], normals[2]]


func mark_hit() -> void:
	pass
