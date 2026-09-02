extends Node2D

@export var max_bounces: int = 10
@export var laser_length_fallback: float = 2000.0
@export var laser_color: Color = Color(1, 1, 0)
@export var laser_width: float = 3.0
@export var start_direction: Vector2 = Vector2.RIGHT

# --- Pengaturan glow (muncul sebagai slider di Inspector) ---
@export_range(0, 25, 1) var glow_layers: int = 12                     # jumlah lapisan blur
@export_range(0.5, 15.0, 0.1) var glow_width_multiplier: float = 6.0  # seberapa lebar area buremnya
@export_range(0.0, 1.0, 0.01) var glow_alpha: float = 0.5             # seberapa pekat/terang buremnya
@export_range(0.5, 5.0, 0.1) var glow_softness: float = 2.5           # >1 = falloff lebih halus/lembut

var start_position: Vector2


func _ready() -> void:
	start_position = global_position


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Sekarang bisa ada LEBIH DARI SATU jalur laser (karena prism memecah cahaya)
	var all_paths: Array = _calculate_laser_paths()
	for points in all_paths:
		if points.size() < 2:
			continue
		_draw_path(points)


func _draw_path(points: Array) -> void:
	# --- Layer glow (dari paling lebar/transparan ke paling tipis) ---
	for layer in range(glow_layers, 0, -1):
		var t: float = float(layer) / float(glow_layers)
		var falloff: float = pow(t, glow_softness)  # falloff halus, bukan linear
		var width: float = laser_width + laser_width * glow_width_multiplier * t
		width = min(width, laser_width * 25.0) # pengaman: glow tidak akan pernah lebih dari 25x tebal laser
		var alpha: float = glow_alpha * falloff
		var glow_color := Color(laser_color.r, laser_color.g, laser_color.b, alpha)
		for i in range(points.size() - 1):
			draw_line(to_local(points[i]), to_local(points[i + 1]), glow_color, width, true)
		# Bulatkan sambungan di tiap titik belokan biar rapi, tidak "patah"
		for i in range(points.size()):
			draw_circle(to_local(points[i]), width * 0.5, glow_color)

	# --- Garis inti solid di atas glow ---
	for i in range(points.size() - 1):
		draw_line(to_local(points[i]), to_local(points[i + 1]), laser_color, laser_width, true)
	# Bulatkan sambungan inti juga
	for i in range(points.size()):
		draw_circle(to_local(points[i]), laser_width * 0.5, laser_color)


func _calculate_laser_paths() -> Array:
	var dir: Vector2 = start_direction.normalized().rotated(rotation)
	return _trace_ray(start_position, dir, max_bounces, [])


# Melacak satu ray. Mengembalikan Array berisi satu atau lebih Array[Vector2]
# (lebih dari satu kalau ray ini pecah cabang lewat prism).
func _trace_ray(start_pos: Vector2, start_dir: Vector2, bounces_left: int, exclude_rids: Array[RID]) -> Array:
	var points: Array[Vector2] = [start_pos]
	var current_pos: Vector2 = start_pos
	var current_dir: Vector2 = start_dir
	var local_exclude: Array[RID] = exclude_rids.duplicate()
	var remaining: int = bounces_left

	var space_state := get_world_2d().direct_space_state

	while remaining > 0:
		remaining -= 1

		var query := PhysicsRayQueryParameters2D.create(
			current_pos,
			current_pos + current_dir * laser_length_fallback
		)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = local_exclude

		var result := space_state.intersect_ray(query)

		if result.is_empty():
			points.append(current_pos + current_dir * laser_length_fallback)
			return [points]

		var hit_point: Vector2 = result.position
		var hit_normal: Vector2 = result.normal
		var collider: Object = result.collider
		var collider_rid: RID = result.rid
		points.append(hit_point)

		if collider.is_in_group("door"):
			if collider.has_method("open"):
				collider.open()
			return [points]

		elif collider.is_in_group("trigger"):
			if collider.has_method("mark_hit"):
				collider.mark_hit()
			if _is_front_side(collider, hit_normal):
				current_dir = current_dir.bounce(hit_normal)
				current_pos = hit_point + hit_normal * 4.0
				continue
			else:
				return [points]

		elif collider.is_in_group("house"):
			if collider.has_method("mark_hit"):
				collider.mark_hit()
			# House SELALU tembus lurus, tidak pernah mantul
			local_exclude.append(collider_rid)
			current_pos = hit_point + current_dir * 2.0
			continue

		elif collider.is_in_group("prism"):
			if collider.has_method("mark_hit"):
				collider.mark_hit()
			if not _is_front_side(collider, hit_normal):
				return [points]

			var split_dirs: Array = [current_dir, current_dir]
			if collider.has_method("get_split_directions"):
				split_dirs = collider.get_split_directions(current_dir, hit_normal)

			if remaining <= 0 or split_dirs.size() < 2:
				# Kehabisan jatah bounce atau prism tidak valid -> berhenti di sini saja
				return [points]

			# Prism dianggap "tembus" -> collider-nya di-exclude supaya cabang
			# yang lewat tidak nabrak ulang bentuk yang sama dan pecah berkali-kali.
			var branch_exclude: Array[RID] = local_exclude.duplicate()
			branch_exclude.append(collider_rid)

			var result_paths: Array = []
			for split_dir in split_dirs:
				# Dorong titik mulai tiap cabang sesuai arahnya sendiri-sendiri,
				# supaya benar-benar keluar dari bentuk prism (bukan cuma geser sedikit).
				var branch_start: Vector2 = hit_point + split_dir.normalized() * 8.0
				var sub_paths: Array = _trace_ray(branch_start, split_dir, remaining, branch_exclude)
				for sub in sub_paths:
					var combined: Array[Vector2] = points.duplicate()
					combined.append_array(sub)
					result_paths.append(combined)
			return result_paths

		elif collider.is_in_group("mirror"):
			if _is_front_side(collider, hit_normal):
				current_dir = current_dir.bounce(hit_normal)
				current_pos = hit_point + hit_normal * 4.0
				continue
			else:
				return [points]

		else:
			return [points]

	return [points]


func _is_front_side(collider: Object, hit_normal: Vector2) -> bool:
	if collider.has_method("get_reflect_normal"):
		var front_normal: Vector2 = collider.get_reflect_normal()
		return hit_normal.dot(front_normal) > 0.5
	return true
