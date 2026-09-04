extends Node2D

@export var mirror_scene: PackedScene
@export var max_mirrors: int = 3
@export var mirror_collision_size: Vector2 = Vector2(120, 40)
@export var mirror_counter: CanvasLayer

var spawned_mirrors: Array[Node2D] = []

func _ready() -> void:
	_update_counter()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Create_Glass"):
		_try_spawn_mirror()
	elif event.is_action_pressed("Delete_Glass"):
		_try_delete_last_mirror()

func _try_spawn_mirror() -> void:
	if spawned_mirrors.size() >= max_mirrors:
		if mirror_counter:
			mirror_counter.play_error_effect()
		return
	if mirror_scene == null:
		push_warning("Mirror Scene belum di-assign di Inspector!")
		return
	var spawn_pos: Vector2 = get_global_mouse_position()
	if _is_position_blocked(spawn_pos):
		if mirror_counter:
			mirror_counter.play_error_effect()
		return
	var new_mirror: Node2D = mirror_scene.instantiate()
	new_mirror.global_position = spawn_pos
	add_child(new_mirror)
	spawned_mirrors.append(new_mirror)
	_update_counter()

func _is_position_blocked(pos: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = mirror_collision_size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, pos)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.collision_mask = 0xFFFFFFFF
	var result: Array[Dictionary] = space_state.intersect_shape(query, 8)
	return result.size() > 0

func _try_delete_last_mirror() -> void:
	if spawned_mirrors.is_empty():
		return
	var last_mirror: Node2D = spawned_mirrors.pop_back()
	last_mirror.queue_free()
	_update_counter()

func get_remaining_mirrors() -> int:
	return max_mirrors - spawned_mirrors.size()

func _update_counter() -> void:
	if mirror_counter:
		mirror_counter.set_count(get_remaining_mirrors(), max_mirrors)
