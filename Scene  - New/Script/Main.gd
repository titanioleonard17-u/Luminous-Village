extends Node2D

@export var mirror_scene: PackedScene # drag mirror.tscn ke sini di Inspector
@export var max_mirrors: int = 3 # atur limit per level lewat Inspector
@export var spawn_offset: Vector2 = Vector2(50, 0) # jarak spawn dari posisi mouse, biar gak numpuk

var spawned_mirrors: Array[Node2D] = []

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Create_Glass"):
		_try_spawn_mirror()
	elif event.is_action_pressed("Delete_Glass"):
		_try_delete_last_mirror()

func _try_spawn_mirror() -> void:
	if spawned_mirrors.size() >= max_mirrors:
		print("Limit mirror sudah tercapai! (%d/%d)" % [spawned_mirrors.size(), max_mirrors])
		return
	
	if mirror_scene == null:
		push_warning("Mirror Scene belum di-assign di Inspector!")
		return

	var new_mirror: Node2D = mirror_scene.instantiate()
	new_mirror.global_position = get_global_mouse_position()
	add_child(new_mirror)
	spawned_mirrors.append(new_mirror)
	print("Mirror spawned: %d/%d" % [spawned_mirrors.size(), max_mirrors])

func _try_delete_last_mirror() -> void:
	if spawned_mirrors.is_empty():
		print("Tidak ada mirror untuk dihapus!")
		return

	var last_mirror: Node2D = spawned_mirrors.pop_back()
	last_mirror.queue_free()
	print("Mirror deleted: %d/%d" % [spawned_mirrors.size(), max_mirrors])

func get_remaining_mirrors() -> int:
	return max_mirrors - spawned_mirrors.size()
