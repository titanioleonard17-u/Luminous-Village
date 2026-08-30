extends Node2D

@export var max_bounces: int = 10
@export var laser_length_fallback: float = 2000.0
@export var laser_color: Color = Color(1, 1, 0)
@export var laser_width: float = 3.0
@export var start_direction: Vector2 = Vector2.RIGHT

var start_position: Vector2

func _ready() -> void:
	start_position = global_position

func _physics_process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var points: Array[Vector2] = _calculate_laser_path()
	for i in range(points.size() - 1):
		draw_line(to_local(points[i]), to_local(points[i + 1]), laser_color, laser_width)

func _calculate_laser_path() -> Array[Vector2]:
	var points: Array[Vector2] = [start_position]
	var current_pos: Vector2 = start_position
	var current_dir: Vector2 = start_direction.normalized().rotated(rotation)

	var space_state := get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = []

	for bounce_i in range(max_bounces):
		var query := PhysicsRayQueryParameters2D.create(
			current_pos,
			current_pos + current_dir * laser_length_fallback
		)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = exclude_rids

		var result := space_state.intersect_ray(query)

		if result.is_empty():
			points.append(current_pos + current_dir * laser_length_fallback)
			break

		var hit_point: Vector2 = result.position
		var hit_normal: Vector2 = result.normal
		var collider: Object = result.collider
		var collider_rid: RID = result.rid

		points.append(hit_point)

		if collider.is_in_group("door"):
			if collider.has_method("open"):
				collider.open()
			break
		elif collider.is_in_group("trigger"):
			if collider.has_method("mark_hit"):
				collider.mark_hit()
			var is_front_side: bool = true
			if collider.has_method("get_reflect_normal"):
				var front_normal: Vector2 = collider.get_reflect_normal()
				is_front_side = hit_normal.dot(front_normal) > 0.5
			if is_front_side:
				current_dir = current_dir.bounce(hit_normal)
				current_pos = hit_point + hit_normal * 4.0
			else:
				break
		elif collider.is_in_group("house"):
			if collider.has_method("mark_hit"):
				collider.mark_hit()
			# House SELALU tembus lurus, tidak pernah mantul
			exclude_rids.append(collider_rid)
			current_pos = hit_point + current_dir * 2.0
		elif collider.is_in_group("mirror"):
			var is_front_side: bool = true
			if collider.has_method("get_reflect_normal"):
				var front_normal: Vector2 = collider.get_reflect_normal()
				is_front_side = hit_normal.dot(front_normal) > 0.5
			if is_front_side:
				current_dir = current_dir.bounce(hit_normal)
				current_pos = hit_point + hit_normal * 4.0
			else:
				break
		else:
			break

	return points	
