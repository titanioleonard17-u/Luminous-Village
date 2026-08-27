extends Node3D

@export var glass_scene: PackedScene
@export var max_spawns: int = 3

var spawned_glass: Array = []
var spawns_used: int = 0

func _input(event):
	if event.is_action_pressed("Create_Glass"):
		var camera = get_viewport().get_camera_3d()
		if camera == null:
			print("Kamera tidak ditemukan!")
			return
		var mouse_pos = get_viewport().get_mouse_position()
		var spawn_pos = _get_ground_position(mouse_pos, camera)
		if spawn_pos != null:
			spawn_glass(spawn_pos)
		else:
			print("Tidak bisa menentukan posisi spawn dari klik ini.")
	elif event.is_action_pressed("Delete_Glass"):
		remove_last_glass()

func _get_ground_position(screen_pos: Vector2, camera: Camera3D):
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	if abs(dir.y) < 0.0001:
		return null
	var t = -from.y / dir.y
	if t < 0:
		return null
	return from + dir * t

func can_spawn() -> bool:
	return spawns_used < max_spawns

func spawn_glass(pos: Vector3) -> Node3D:
	if not can_spawn():
		print("Limit spawn kaca sudah habis!")
		return null

	var new_glass = glass_scene.instantiate()
	add_child(new_glass)
	new_glass.global_position = pos
	spawned_glass.append(new_glass)
	spawns_used += 1
	print("Kaca ke-", spawns_used, " di-spawn di posisi: ", pos)
	return new_glass

func remove_last_glass():
	if spawned_glass.is_empty():
		print("Tidak ada kaca untuk dihapus.")
		return
	var last_glass = spawned_glass.pop_back()
	last_glass.queue_free()
	spawns_used -= 1
	print("Kaca dihapus. Sisa slot: ", max_spawns - spawns_used)
