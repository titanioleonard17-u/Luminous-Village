extends Camera2D

@export var zoom_step := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 2.0
@export var zoom_duration := 0.2

@export_category("Camera Limit Expand")
@export var expand_left := 0.0
@export var expand_right := 0.0
@export var expand_top := 0.0
@export var expand_bottom := 0.0

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


func _ready():
	limit_left -= int(expand_left)
	limit_right += int(expand_right)
	limit_top -= int(expand_top)
	limit_bottom += int(expand_bottom)

	target_position = position


func _process(delta):
	if get_tree().paused:
		dragging = false
		return

	if dragging:
		position = position.lerp(
			target_position,
			1.0 - exp(-drag_smooth * delta)
		)

	position.x = clamp(position.x, limit_left, limit_right)
	position.y = clamp(position.y, limit_top, limit_bottom)


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
				if is_mouse_on_mirror() or is_mouse_on_ui_button():
					dragging = false
					return

				dragging = true
				target_position = position

			else:
				dragging = false

	# =========================
	# MOUSE DRAG
	# =========================
	if event is InputEventMouseMotion and dragging:

		# Abaikan MouseMotion yang berasal
		# dari Input.warp_mouse()
		if wrapping_mouse:
			wrapping_mouse = false
			return

		# Gunakan RELATIVE movement.
		# Tidak menggunakan event.position - last_position
		# supaya teleport cursor tidak ikut dihitung.
		var movement = event.relative

		target_position -= movement / zoom.x

		# =========================
		# MOUSE WRAP
		# =========================
		var mouse_position = event.position
		var viewport_size = get_viewport_rect().size

		var wrap_position = mouse_position
		var should_wrap = false

		# Kiri -> kanan
		if mouse_position.x <= wrap_margin:
			wrap_position.x = viewport_size.x - wrap_margin
			should_wrap = true

		# Kanan -> kiri
		elif mouse_position.x >= viewport_size.x - wrap_margin:
			wrap_position.x = wrap_margin
			should_wrap = true

		# Atas -> bawah
		if mouse_position.y <= wrap_margin:
			wrap_position.y = viewport_size.y - wrap_margin
			should_wrap = true

		# Bawah -> atas
		elif mouse_position.y >= viewport_size.y - wrap_margin:
			wrap_position.y = wrap_margin
			should_wrap = true

		if should_wrap:
			wrapping_mouse = true
			Input.warp_mouse(wrap_position)

		# =========================
		# CAMERA LIMIT
		# =========================
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
