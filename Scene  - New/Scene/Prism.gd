extends StaticBody2D

## Sudut sisi pertama segitiga (derajat), diukur dari sumbu X (kanan).
## Kalau arah keluar cahayanya nggak pas sama sprite, geser nilai ini.
@export_range(-180, 180, 1) var forward_offset_deg: float = 0.0

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


## Menghitung arah normal (mengarah keluar) dari 3 sisi segitiga, berdasar
## rotasi objek + forward_offset_deg. Segitiga dianggap simetris, jadi
## 3 sisinya dianggap berjarak 120° satu sama lain.
func _get_face_normals() -> Array:
	var base_angle: float = deg_to_rad(forward_offset_deg) + global_rotation
	var normals: Array = []
	for i in range(3):
		normals.append(Vector2.from_angle(base_angle + deg_to_rad(120.0 * i)))
	return normals


## Sisi "masuk" (yang bisa mancarin cahaya) -- cuma sisi ini yang aktif.
## 2 sisi lainnya diperlakukan Laser.gd sebagai collision biasa (laser
## berhenti di situ, tidak pecah).
func get_reflect_normal() -> Vector2:
	return _get_face_normals()[0]


## Titik asal kedua cabang cahaya. Dipakai Laser.gd (kalau ada) supaya
## cabang mulai dari TENGAH segitiga -- bukan dari titik tabrak di sisi
## masuk -- jadi keluarnya simetris ke arah 2 pojok lainnya, kayak
## prisma beneran (bukan miring/nggak pas pojok).
func get_split_origin() -> Vector2:
	return global_position


## Dipanggil Laser.gd saat ray kena prism DARI SISI MASUK (sisi 0) saja.
## Kalau kena sisi lain, Laser.gd sudah berhenti duluan sebelum sampai sini
## (lihat get_reflect_normal() di atas), jadi di sini tinggal keluarkan
## cahaya ke 2 sisi lainnya.
func get_split_directions(_incoming_dir: Vector2, _hit_normal: Vector2) -> Array:
	var normals: Array = _get_face_normals()
	return [normals[1], normals[2]]


func mark_hit() -> void:
	pass # opsional: taruh efek visual/partikel di sini kalau mau
