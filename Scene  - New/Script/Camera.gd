extends Camera2D

@export var zoom_scale := 0.5
@export var zoom_step := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 1.0
@export var zoom_duration := 0.2

@export_category("Camera Limit Expand")
@export var expand_left := 0.0
@export var expand_right := 0.0
@export var expand_top := 0.0
@export var expand_bottom := 0.0

@export_category("Zoom Limit Expansion")
@export var max_expand_left: float = 300.0
@export var max_expand_right: float = 800.0
@export var max_expand_top: float = 300.0
@export var max_expand_bottom: float = 300.0

@export_category("Mouse Wrap")
@export var wrap_margin := 2.0

@export_category("Drag Smooth")
@export var drag_smooth := 12.0

@onready var help_trigger = $"../PauseTrigger/Container/MarginContainer/PauseNavigation/HelpButton"
@onready var pause_trigger = $"../PauseTrigger/Container/MarginContainer/PauseNavigation/PauseButton"

var dragging := false
var target_position := Vector2.ZERO
var zoom_tween: Tween
var wrapping_mouse := false
var is_step_guide_active: bool = false

var original_limit_left: int
var original_limit_right: int
var original_limit_top: int
var original_limit_bottom: int


func _ready():
	zoom = Vector2(zoom_scale, zoom_scale)

	# Terapkan expand dari Inspector
	limit_left -= int(expand_left)
	limit_right += int(expand_right)
	limit_top -= int(expand_top)
	limit_bottom += int(expand_bottom)

	# Simpan limit default level
	original_limit_left = limit_left
	original_limit_right = limit_right
	original_limit_top = limit_top
	original_limit_bottom = limit_bottom

	target_position = position


func _process(delta):
	if get_tree().paused or is_step_guide_active:
		dragging = false
		return

	if dragging:
		position = position.lerp(
			target_position,
			1.0 - exp(-drag_smooth * delta)
		)

	position.x = clamp(
		position.x,
		limit_left,
		limit_right
	)

	position.y = clamp(
		position.y,
		limit_top,
		limit_bottom
	)


func _input(event):
	if get_tree().paused:
		dragging = false
		return

	# =========================
	# MOUSE BUTTON
	# =========================
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				if is_mouse_on_mirror() or is_mouse_on_ui_button() or is_mouse_on_sensitivity_slider():
					dragging = false
					return

				dragging = true
				target_position = position
			else:
				dragging = false

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				print(get_tree().paused)
				change_zoom(1.0)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				change_zoom(-1.0)

	# =========================
	# MOUSE DRAG
	# =========================
	elif event is InputEventMouseMotion and dragging:

		if wrapping_mouse:
			wrapping_mouse = false
			return

		var movement: Vector2 = event.relative
		target_position -= movement / zoom.x

		var mouse_position: Vector2 = event.position
		var viewport_size: Vector2 = get_viewport_rect().size

		var wrap_position: Vector2 = mouse_position
		var should_wrap: bool = false

		if mouse_position.x <= wrap_margin:
			wrap_position.x = viewport_size.x - wrap_margin
			should_wrap = true
		elif mouse_position.x >= viewport_size.x - wrap_margin:
			wrap_position.x = wrap_margin
			should_wrap = true

		if mouse_position.y <= wrap_margin:
			wrap_position.y = viewport_size.y - wrap_margin
			should_wrap = true
		elif mouse_position.y >= viewport_size.y - wrap_margin:
			wrap_position.y = wrap_margin
			should_wrap = true

		if should_wrap:
			wrapping_mouse = true
			Input.warp_mouse(wrap_position)

		target_position.x = clamp(
			target_position.x,
			limit_left,
			limit_right
		)

		target_position.y = clamp(
			target_position.y,
			limit_top,
			limit_bottom
		)


func change_zoom(direction: float) -> void:
	var old_zoom: float = zoom.x

	var new_zoom: float = clampf(
		old_zoom + direction * zoom_step,
		min_zoom,
		max_zoom
	)

	if is_equal_approx(new_zoom, old_zoom):
		return

	# =========================
	# HITUNG PROGRESS ZOOM
	# =========================
	var zoom_range: float = max_zoom - min_zoom
	var zoom_progress: float = 0.0

	if zoom_range > 0.0:
		zoom_progress = (new_zoom - min_zoom) / zoom_range

	zoom_progress = clampf(
		zoom_progress,
		0.0,
		1.0
	)

	# =========================
	# HITUNG TAMBAHAN LIMIT
	# SAAT ZOOM
	# =========================
	var current_expand_left: float = max_expand_left * zoom_progress
	var current_expand_right: float = max_expand_right * zoom_progress
	var current_expand_top: float = max_expand_top * zoom_progress
	var current_expand_bottom: float = max_expand_bottom * zoom_progress

	# =========================
	# TERAPKAN LIMIT ZOOM
	# =========================
	limit_left = original_limit_left - int(current_expand_left)
	limit_right = original_limit_right + int(current_expand_right)
	limit_top = original_limit_top - int(current_expand_top)
	limit_bottom = original_limit_bottom + int(current_expand_bottom)

	# =========================
	# ZOOM
	# =========================
	zoom = Vector2(new_zoom, new_zoom)

	target_position = position


func is_mouse_on_mirror() -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results = space_state.intersect_point(query)

	for result in results:
		var collider = result.collider

		if collider.is_in_group("mirror"):
			return true

		if collider.get_parent() and collider.get_parent().is_in_group("cermin"):
			return true

	return false


func is_mouse_on_ui_button() -> bool:
	var mouse_position = get_viewport().get_mouse_position()

	if pause_trigger.get_global_rect().has_point(mouse_position):
		return true

	if help_trigger.get_global_rect().has_point(mouse_position):
		return true

	return false


func is_mouse_on_sensitivity_slider() -> bool:
	var sliders = get_tree().get_nodes_in_group("sensitivity_slider")

	for slider in sliders:
		if slider.has_method("is_mouse_over"):
			if slider.is_mouse_over():
				return true

	return false


func set_step_guide_status(value: bool) -> void:
	is_step_guide_active = value
