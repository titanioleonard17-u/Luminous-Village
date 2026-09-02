extends StaticBody2D

## Sudut pisah tiap cabang dari arah datang laser (derajat).
## 20 berarti cabang kiri belok +20°, cabang kanan belok -20°.
@export_range(5, 89, 1) var split_angle_deg: float = 20.0

## Kalau arah sebarannya kebalik dari yang diharapkan, centang ini di
## Inspector -- nggak perlu edit kode lagi, tinggal toggle.
@export var invert_pass_through: bool = false

var is_dragging: bool = false
var touch_index: int = -1


func _ready() -> void:
	add_to_group("prism")


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


## Sisi "depan" prism (yang bisa memecah cahaya). Sesuaikan arah ini
## dengan orientasi sprite/collision shape segitiga kalian.
func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)


## Arah "tembus" default prism -- ini yang jadi pusat/tengah dari 2 cabang.
## Selalu mengikuti rotasi objek secara penuh & smooth (nggak di-clamp),
## supaya muter kanan/kiri kerasa natural. Kalau arahnya kebalik, centang
## invert_pass_through di Inspector.
func get_pass_through_direction() -> Vector2:
	var base_dir: Vector2 = Vector2.LEFT if invert_pass_through else Vector2.RIGHT
	return base_dir.rotated(global_rotation)


## Dipanggil Laser.gd saat ray kena prism dari sisi depan.
## Pusat sebaran mengikuti rotasi objek secara penuh & smooth.
func get_split_directions(_incoming_dir: Vector2, _hit_normal: Vector2) -> Array:
	var forward: Vector2 = get_pass_through_direction()
	var half_angle_rad: float = deg_to_rad(split_angle_deg) * 0.5
	var branch_a: Vector2 = forward.rotated(half_angle_rad)
	var branch_b: Vector2 = forward.rotated(-half_angle_rad)
	return [branch_a, branch_b]


func mark_hit() -> void:
	pass # opsional: taruh efek visual/partikel di sini kalau mau
