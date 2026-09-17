extends StaticBody2D

@export var interact_radius: float = 100.0
@export var ball_ratio: float = 0.18
@export var facing_offset_degrees: float = 90.0
@export var rotation_speed: float = 0.25

@export var linked_teleporter: NodePath          # target teleporter tujuan
@export var preserve_incoming_direction: bool = false  # true = arah laser tetap sama, false = ikut rotasi teleporter tujuan
@export var exit_offset: float = 8.0
@export var allow_incoming: bool = true          # false = objek ini exit-only, tidak bisa jadi pintu masuk laser

var is_dragging: bool = false
var touch_index: int = -1
var joystick_ui: JoystickUI

func _ready() -> void:
	add_to_group("teleporter")

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

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_point_over(get_global_mouse_position()):
				_start_drag()
			else:
				_end_drag()

	if event is InputEventMouseMotion and is_dragging:
		_rotate_towards(get_global_mouse_position())

	if event is InputEventScreenTouch:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and _is_point_over(world_pos):
			touch_index = event.index
			_start_drag()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			_end_drag()

	if event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_rotate_towards(world_pos)

func _start_drag() -> void:
	is_dragging = true
	joystick_ui.global_position = global_position
	joystick_ui.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _end_drag() -> void:
	is_dragging = false
	joystick_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _rotate_towards(world_pos: Vector2) -> void:
	var direction: Vector2 = world_pos - global_position
	var mouse_angle: float = direction.angle()
	var target_rotation: float = mouse_angle - deg_to_rad(facing_offset_degrees)

	rotation = lerp_angle(rotation, target_rotation, rotation_speed)
	joystick_ui.set_angle(mouse_angle)

func _is_point_over(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) < interact_radius

# --- Ini bagian utama untuk laser ---
func get_teleport_exit(incoming_dir: Vector2) -> Variant:
	if linked_teleporter.is_empty():
		return null

	var target: Node = get_node_or_null(linked_teleporter)
	if target == null or not (target is Node2D):
		return null

	var out_dir: Vector2 = incoming_dir
	if not preserve_incoming_direction:
		out_dir = Vector2.RIGHT.rotated(target.global_rotation + deg_to_rad(target.facing_offset_degrees))

	var out_pos: Vector2 = target.global_position + out_dir * exit_offset

	var exclude_rid: RID = RID()
	if target is CollisionObject2D:
		exclude_rid = (target as CollisionObject2D).get_rid()

	return {
		"position": out_pos,
		"direction": out_dir,
		"exclude_rid": exclude_rid
	}

func mark_hit() -> void:
	pass # kalau mau efek visual pas kena laser, taruh di sini
