extends StaticBody2D

@export var interact_radius: float = 100.0
@export var ball_ratio: float = 0.18
@export var facing_offset_degrees: float = 90.0
@export var rotation_speed: float = 0.25       # fallback sensitivity (0..1), dipakai kalau slider belum di-set
@export var sensitivity_scale: float = 0.015   # radian per pixel per unit sensitivity, di sini lo tuning "berat/ringan"-nya

var is_dragging: bool = false
var touch_index: int = -1
var is_locked: bool = false

var joystick_ui: JoystickUI

# Sensitivity aktif dari slider (0..1). -1 artinya belum pernah di-set, pakai rotation_speed default
var active_sensitivity: float = -1.0

func _ready() -> void:
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

func _input(event: InputEvent) -> void:
	if is_locked:
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

	if event is InputEventMouseMotion and is_dragging:
		_apply_rotation_delta(event.relative)

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
		_apply_rotation_delta(event.relative)

func _start_drag() -> void:
	is_dragging = true
	joystick_ui.global_position = global_position
	joystick_ui.visible = true
	# CAPTURED, bukan HIDDEN: cursor OS di-lock di posisi klik, gak keliatan gerak sama sekali.
	# Kita cuma baca delta gerakan mouse (event.relative), bukan posisi absolutnya.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _end_drag() -> void:
	is_dragging = false
	joystick_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_rotation_delta(relative: Vector2) -> void:
	var sensitivity: float = rotation_speed
	if active_sensitivity >= 0.0:
		sensitivity = active_sensitivity
	sensitivity = clamp(sensitivity, 0.0, 1.0)

	if sensitivity <= 0.0:
		return

	# Arah hadap objek saat ini, dan arah tangensial (tegak lurus)-nya.
	var current_dir: Vector2 = Vector2.RIGHT.rotated(rotation + deg_to_rad(facing_offset_degrees))
	var tangent: Vector2 = current_dir.rotated(PI / 2.0)

	# Proyeksikan gerakan mouse ke arah tangensial -> itu yang jadi delta rotasi.
	# Gerak mouse "muter" di sekitar arah hadap = muter objek. Gerak lurus menjauh/mendekat = gak ngaruh.
	var delta_angle: float = relative.dot(tangent) * sensitivity_scale * sensitivity

	rotation += delta_angle
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

func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)

func set_locked(value: bool) -> void:
	is_locked = value

# Dipanggil dari SensitivityDragSlider. raw_value ada di rentang [0, max_value] slider,
# di sini kita normalize ke rentang [0, 1] sebelum dipakai buat scale kecepatan rotasi.
func set_sensitivity(raw_value: float, raw_max: float) -> void:
	if raw_max <= 0.0:
		active_sensitivity = 0.0
		return
	active_sensitivity = clamp(raw_value / raw_max, 0.0, 1.0)
