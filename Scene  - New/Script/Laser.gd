extends Node2D

@export var max_bounces: int = 10
@export var laser_length_fallback: float = 2000.0
@export var laser_color: Color = Color(1, 0.1, 0.1) # merah
@export var laser_width: float = 3.0
@export var start_direction: Vector2 = Vector2.RIGHT

# --- Pengaturan glow (muncul sebagai slider di Inspector) ---
@export_range(0, 25, 1) var glow_layers: int = 20                     # jumlah lapisan blur
@export_range(0.5, 15.0, 0.1) var glow_width_multiplier: float = 10.0 # seberapa lebar area buremnya
@export_range(0.0, 1.0, 0.01) var glow_alpha: float = 0.18            # seberapa pekat/terang buremnya (lebih rendah = lebih transparan)
@export_range(0.5, 5.0, 0.1) var glow_softness: float = 3.0           # >1 = falloff lebih halus/lembut

# --- Fade sepanjang path (biar keseluruhan laser transparan & ujungnya hilang) ---
@export var fade_along_length: bool = true
@export_range(0.0, 1.0, 0.01) var fade_start_ratio: float = 0.0   # 0 = mulai fade dari sumber, 0.5 = separuh jalan baru mulai fade
@export_range(0.5, 5.0, 0.1) var fade_softness: float = 1.8       # >1 = fade lebih landai di awal, cepat di ujung

# --- Sambungan pojok (joint) ---
@export var round_joints: bool = true   # gambar lingkaran di tiap titik belokan biar bundar & rapi, gak "patah"

# --- Efek glow di titik tumbukan (pas kena mirror/prism/dinding/ujung) ---
@export var impact_glow_enabled: bool = true
@export_range(0.5, 6.0, 0.1) var impact_glow_radius_multiplier: float = 1.8  # radius glow relatif ke laser_width
@export_range(0.0, 1.0, 0.01) var impact_glow_alpha: float = 0.6           # kecerahan inti glow
@export_range(2, 15, 1) var impact_glow_layers: int = 8                    # jumlah lapisan lingkaran (radial falloff)
@export_range(0.5, 4.0, 0.1) var impact_glow_softness: float = 2.2          # >1 = falloff lebih landai/halus di pinggir

var start_position: Vector2


func _ready() -> void:
	start_position = global_position

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var all_paths: Array = _calculate_laser_paths()
	for points in all_paths:
		if points.size() < 2:
			continue
		_draw_path(points)


func _draw_path(points: Array) -> void:
	var total_length: float = 0.0
	for i in range(points.size() - 1):
		total_length += (points[i + 1] - points[i]).length()
	if total_length <= 0.0:
		total_length = 1.0

	var _fade_at = func(dist: float) -> float:
		if not fade_along_length:
			return 1.0
		var ratio: float = dist / total_length
		if ratio <= fade_start_ratio:
			return 1.0
		var span: float = max(1.0 - fade_start_ratio, 0.0001)
		var local_ratio: float = (ratio - fade_start_ratio) / span
		local_ratio = clamp(local_ratio, 0.0, 1.0)
		return pow(1.0 - local_ratio, fade_softness)

	for layer in range(glow_layers, 0, -1):
		var t: float = float(layer) / float(glow_layers)
		var falloff: float = pow(t, glow_softness)
		var base_alpha: float = glow_alpha * falloff

		var max_width: float = laser_width + laser_width * glow_width_multiplier * t
		max_width = min(max_width, laser_width * 25.0)

		var traveled: float = 0.0
		for i in range(points.size() - 1):
			var p0: Vector2 = to_local(points[i])
			var p1: Vector2 = to_local(points[i + 1])
			var seg_dir: Vector2 = (p1 - p0).normalized()
			var normal: Vector2 = Vector2(-seg_dir.y, seg_dir.x)
			var seg_len: float = (points[i + 1] - points[i]).length()

			# Lebar konstan sepanjang laser (tidak taper)
			var width_start: float = max_width
			var width_end: float = max_width

			var alpha_start: float = base_alpha * _fade_at.call(traveled)
			var alpha_end: float = base_alpha * _fade_at.call(traveled + seg_len)

			var color_start := Color(laser_color.r, laser_color.g, laser_color.b, alpha_start)
			var color_end := Color(laser_color.r, laser_color.g, laser_color.b, alpha_end)

			var poly := PackedVector2Array([
				p0 - normal * width_start * 0.5,
				p1 - normal * width_end * 0.5,
				p1 + normal * width_end * 0.5,
				p0 + normal * width_start * 0.5,
			])
			var poly_colors := PackedColorArray([color_start, color_end, color_end, color_start])
			draw_polygon(poly, poly_colors)

			traveled += seg_len

		# --- Bundarin tiap titik sambungan (bend point) biar gak "patah/nabrak" ---
		if round_joints and points.size() > 2:
			var traveled_joint: float = 0.0
			for i in range(points.size() - 1):
				var seg_len_j: float = (points[i + 1] - points[i]).length()
				traveled_joint += seg_len_j
				# hanya titik tengah (bukan titik awal/akhir laser) yang perlu dibundarkan
				if i < points.size() - 2:
					var joint_local: Vector2 = to_local(points[i + 1])
					var joint_alpha: float = base_alpha * _fade_at.call(traveled_joint)
					var joint_color := Color(laser_color.r, laser_color.g, laser_color.b, joint_alpha)
					draw_circle(joint_local, max_width * 0.5, joint_color)

	# --- Glow radial di setiap titik tumbukan (bukan cuma joint segmen laser) ---
	# Dibuat SEKALI di luar loop layer (fungsinya sendiri sudah punya banyak layer),
	# supaya efeknya konsisten dan tidak ikut kena "max_width" tiap glow_layers.
	if impact_glow_enabled:
		var traveled_impact: float = 0.0
		for i in range(points.size() - 1):
			traveled_impact += (points[i + 1] - points[i]).length()
			# titik awal (index 0, sumber laser) sengaja dilewati
			var impact_pos: Vector2 = to_local(points[i + 1])
			var impact_fade: float = _fade_at.call(traveled_impact)
			_draw_impact_glow(impact_pos, impact_fade)


func _draw_impact_glow(pos: Vector2, fade: float) -> void:
	# Lingkaran radial (inti terang di tengah, makin ke luar makin buram/transparan)
	# supaya titik tumbukan keliatan natural, bukan cuma "kepotong" rata.
	# Basisnya dihitung dari lebar glow TERLEBAR (bukan cuma laser_width), supaya
	# lingkarannya cukup besar buat nutup semua sudut/pojok kotak segmen laser.
	var widest_glow_width: float = laser_width + laser_width * glow_width_multiplier
	widest_glow_width = min(widest_glow_width, laser_width * 25.0)
	var core_radius: float = widest_glow_width * 0.5
	var max_radius: float = core_radius * impact_glow_radius_multiplier

	for layer in range(impact_glow_layers, 0, -1):
		var t: float = float(layer) / float(impact_glow_layers)
		var radius: float = max_radius * t
		var alpha: float = impact_glow_alpha * pow(1.0 - t, impact_glow_softness) * fade
		if alpha <= 0.001:
			continue
		var color := Color(laser_color.r, laser_color.g, laser_color.b, alpha)
		draw_circle(pos, radius, color)

	# inti terang yang nutup penuh lebar glow segmen (biar sudut kotaknya ketutup total)
	var core_color := Color(1.0, 1.0, 1.0, impact_glow_alpha * fade)
	draw_circle(pos, core_radius, core_color)


func _calculate_laser_paths() -> Array:
	var dir: Vector2 = start_direction.normalized().rotated(rotation)
	return _trace_ray(start_position, dir, max_bounces, [])


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
				return [points]

			var branch_exclude: Array[RID] = local_exclude.duplicate()
			branch_exclude.append(collider_rid)

			var split_origin: Vector2 = hit_point
			if collider.has_method("get_split_origin"):
				split_origin = collider.get_split_origin()

			var result_paths: Array = []
			for split_dir in split_dirs:
				var branch_start: Vector2 = split_origin + split_dir.normalized() * 8.0
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
