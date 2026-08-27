extends Node3D

@export var glass_scene: PackedScene
@export var max_spawns: int = 3

var spawn_positions: Array = [
	Vector3(-1.5, 0, 0),
	Vector3(0, 0, 0),
	Vector3(1.5, 0, 0)
]

var spawned_glass: Array = []
var spawns_used: int = 0

func _input(event):
	if event.is_action_pressed("Create_Glass"):
		if spawns_used < spawn_positions.size():
			spawn_glass(spawn_positions[spawns_used])
		else:
			print("Limit spawn kaca sudah habis!")
	elif event.is_action_pressed("Delete_Glass"):
		remove_last_glass()

func spawn_glass(pos: Vector3) -> Node3D:
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
	print("Kaca dihapus. Sisa slot: ", spawn_positions.size() - spawns_used)
