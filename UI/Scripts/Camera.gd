extends Camera2D

@export var zoom_step := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 2.0
@export var zoom_duration := 0.2

@export_category("Camera Limit Expand")
@export var expand_x := 0.0
@export var expand_y := 0.0

var dragging := false
var last_mouse_position := Vector2.ZERO
var zoom_tween: Tween

var original_limit_left: int
var original_limit_right: int
var original_limit_top: int
var original_limit_bottom: int


func _ready():
	original_limit_left = limit_left
	original_limit_right = limit_right
	original_limit_top = limit_top
	original_limit_bottom = limit_bottom

	limit_left -= int(expand_x / 2.0)
	limit_right += int(expand_x / 2.0)
	limit_top -= int(expand_y / 2.0)
	limit_bottom += int(expand_y / 2.0)


func _input(event):
	# Drag map
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_mouse_on_mirror():
					dragging = false
					return

				dragging = true
				last_mouse_position = event.position
			else:
				dragging = false

	# Gerakkan kamera saat drag
	if event is InputEventMouseMotion and dragging:
		var movement = event.position - last_mouse_position
		position -= movement / zoom.x
		last_mouse_position = event.position

		# Jangan lewat Camera2D limit
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

	# Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom_level(zoom.x + zoom_step, event.position)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom_level(zoom.x - zoom_step, event.position)


func set_zoom_level(target: float, mouse_position: Vector2):
	target = clamp(target, min_zoom, max_zoom)

	if is_equal_approx(zoom.x, target):
		return

	var mouse_world_position = get_global_mouse_position()

	if zoom_tween:
		zoom_tween.kill()

	var new_zoom = Vector2(target, target)

	zoom_tween = create_tween()
	zoom_tween.set_trans(Tween.TRANS_QUAD)
	zoom_tween.set_ease(Tween.EASE_OUT)

	zoom_tween.parallel().tween_property(
		self,
		"zoom",
		new_zoom,
		zoom_duration
	)

	var zoom_ratio = zoom.x / target
	var new_position = mouse_world_position + (position - mouse_world_position) * zoom_ratio

	zoom_tween.parallel().tween_property(
		self,
		"position",
		new_position,
		zoom_duration
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


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_mouse_on_mirror():
					return

				dragging = true
				last_mouse_position = event.position
			else:
				dragging = false
