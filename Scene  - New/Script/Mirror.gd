extends StaticBody2D

@export var interact_radius: float = 100.0
@export var ball_ratio: float = 0.18
@export var facing_offset_degrees: float = 90.0
@export var rotation_speed: float = 0.35       # lerp weight per detik (0..1), makin gede makin responsif
@export var min_drag_distance: float = 20.0    # dead zone anti-blink pas mouse deket pivot

# --- Tuning kecepatan rotasi berdasarkan sensitivitas ---
@export var min_tau: float = 0.05      # waktu respon (detik) di sensitivitas MAKSIMUM (paling gesit)
@export var max_tau: float = 2.5       # waktu respon (detik) di sensitivitas MINIMUM (paling berat)
@export var response_curve: float = 0.5
# ^ INI kunci buat rasa "tengah berat" yang kamu komplain.
#   = 1.0  -> lurus/linear (rentang tengah numpuk ke berat, kayak sekarang)
#   < 1.0  -> tengah & bawah jadi lebih gesit lebih cepat (misal 0.5 = mirip akar kuadrat)
#   > 1.0  -> makin ekstrem numpuk berat di tengah-bawah, gesit cuma di ujung atas banget
#   Coba mulai dari 0.5, kalau masih berat turunin ke 0.35-0.4

var is_dragging: bool = false
var touch_index: int = -1
var is_locked: bool = false
var is_step_guide_active: bool = false

var joystick_ui: JoystickUI
var touch_world_pos: Vector2 = Vector2.ZERO   # dipakai buat sumber posisi kalau drag via touch

# Sensitivity aktif dari slider (0..1). -1 artinya belum pernah di-set, pakai rotation_speed default
var active_sensitivity: float = -1.0

# Cursor 1x1 transparan, fallback kalau MOUSE_MODE_HIDDEN gak reliable di platform tertentu
var _blank_cursor: ImageTexture

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

	var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	_blank_cursor = ImageTexture.create_from_image(img)

func _input(event: InputEvent) -> void:
	if is_locked or is_step_guide_active:
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

	# Poll posisi mouse tiap FRAME (bukan nunggu event motion) -> gerakan konsisten
	# ngikutin frame rate game, gak lagi tersendat kalau event OS jarang nembak.
	var world_pos: Vector2
	if touch_index != -1:
		world_pos = touch_world_pos
	else:
		world_pos = get_global_mouse_position()

	_rotate_towards(world_pos, delta)

func _start_drag() -> void:
	is_dragging = true
	joystick_ui.global_position = global_position
	joystick_ui.visible = true

	# HIDDEN + custom cursor transparan sebagai fallback, biar beneran invisible
	# di platform manapun (MOUSE_MODE_HIDDEN kadang gak konsisten, khususnya web/HTML5).
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.set_custom_mouse_cursor(_blank_cursor)

func _end_drag() -> void:
	is_dragging = false
	joystick_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.set_custom_mouse_cursor(null)   # balikin cursor normal

	# get_screen_transform() convert world -> koordinat WINDOW/OS yang sebenarnya,
	# otomatis handle stretch mode/scale, beda sama get_canvas_transform() yang cuma
	# kasih koordinat internal viewport (itu penyebab teleport jauh kemarin).
	var screen_pos: Vector2 = get_viewport().get_screen_transform() * global_position
	Input.warp_mouse(screen_pos)

func _rotate_towards(world_pos: Vector2, delta: float) -> void:
	var direction: Vector2 = world_pos - global_position

	# Dead zone: kalau mouse kepentok terlalu deket pivot, sudutnya gak stabil -> skip.
	if direction.length() < min_drag_distance:
		return

	var mouse_angle: float = direction.angle()
	var target_rotation: float = mouse_angle - deg_to_rad(facing_offset_degrees)

	var t: float = rotation_speed
	if active_sensitivity >= 0.0:
		t = active_sensitivity
	t = clamp(t, 0.0, 1.0)

	if t <= 0.0:
		return

	# t dilengkungkan dulu pake response_curve sebelum di-lerp ke tau.
	# curve < 1 -> "menaikkan" nilai t kecil-menengah, jadi kerasa gesit lebih cepat
	# begitu slider digeser dikit dari bawah, gak numpuk berat semua di tengah.
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

func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)

func set_locked(value: bool) -> void:
	is_locked = value

	if is_locked:
		if is_dragging:
			_end_drag()
		else:
			joystick_ui.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.set_custom_mouse_cursor(null)

func set_step_guide_status(value: bool) -> void:
	is_step_guide_active = value

# Dipanggil dari SensitivityDragSlider. raw_value ada di rentang [0, max_value] slider,
# di sini kita normalize ke rentang [0, 1] sebelum dipakai sebagai lerp weight.
func set_sensitivity(raw_value: float, raw_max: float) -> void:
	if raw_max <= 0.0:
		active_sensitivity = 0.0
		return
	active_sensitivity = clamp(raw_value / raw_max, 0.0, 1.0)	
