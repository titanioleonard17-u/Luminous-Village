extends CanvasLayer

@export var area_size: Vector2 = Vector2(1280, 720)

# Ukuran light
@export var min_light_scale: float = 0.6
@export var max_light_scale: float = 1.2

# Kecepatan light
@export var min_speed: float = 4.0
@export var max_speed: float = 10.0

# Seberapa jauh light boleh keluar sebelum dipindahkan
@export var light_margin: float = 100.0

# Warna semua light
@export var light_color: Color = Color(1.0, 0.85, 0.3, 1.0)

var lights: Array[PointLight2D] = []
var spawn_positions: Array[Vector2] = []


func _ready() -> void:
	randomize()

	_get_lights()
	_generate_spawn_positions()
	_setup_lights()


func _process(delta: float) -> void:
	for light: PointLight2D in lights:
		_move_light(light, delta)

		if _is_outside(light):
			_respawn_light(light)


func _get_lights() -> void:
	lights.clear()

	for child: Node in $Container/LightNode.get_children():
		if child is PointLight2D:
			lights.append(child as PointLight2D)


func _generate_spawn_positions() -> void:
	spawn_positions.clear()

	var light_count: int = lights.size()

	if light_count == 0:
		return

	var columns: int = ceili(sqrt(float(light_count)))
	var rows: int = ceili(float(light_count) / columns)

	var cell_width: float = area_size.x / columns
	var cell_height: float = area_size.y / rows

	for i in range(light_count):
		var column: int = i % columns
		var row: int = i / columns

		var position := Vector2(
			column * cell_width + cell_width * randf_range(0.2, 0.8),
			row * cell_height + cell_height * randf_range(0.2, 0.8)
		)

		spawn_positions.append(position)

	spawn_positions.shuffle()


func _setup_lights() -> void:
	for i in range(lights.size()):
		var light: PointLight2D = lights[i]

		# Posisi awal yang sudah dibuat merata
		light.position = spawn_positions[i]

		# Ukuran random
		var light_scale: float = randf_range(
			min_light_scale,
			max_light_scale
		)

		light.scale = Vector2.ONE * light_scale

		# Warna sama
		light.color = light_color

		# Kecepatan random
		light.set_meta(
			"speed",
			randf_range(min_speed, max_speed)
		)

		# Arah random
		light.set_meta(
			"direction",
			Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized()
		)

		# Simpan scale
		light.set_meta(
			"light_scale",
			light_scale
		)


func _move_light(light: PointLight2D, delta: float) -> void:
	var direction: Vector2 = light.get_meta("direction")
	var speed: float = light.get_meta("speed")

	light.position += direction * speed * delta

	# Perubahan arah secara perlahan
	if randf() < 0.015:
		var new_direction: Vector2 = direction.rotated(
			randf_range(-0.35, 0.35)
		)

		light.set_meta(
			"direction",
			new_direction.normalized()
		)


func _is_outside(light: PointLight2D) -> bool:
	var light_scale: float = light.get_meta(
		"light_scale",
		1.0
	)

	var margin: float = light_margin * light_scale

	return (
		light.position.x < -margin
		or light.position.x > area_size.x + margin
		or light.position.y < -margin
		or light.position.y > area_size.y + margin
	)


func _respawn_light(light: PointLight2D) -> void:
	var new_position: Vector2 = _get_best_spawn_position(light)

	light.position = new_position

	light.set_meta(
		"speed",
		randf_range(min_speed, max_speed)
	)

	light.set_meta(
		"direction",
		Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
	)


func _get_best_spawn_position(current_light: PointLight2D) -> Vector2:
	var best_position: Vector2 = spawn_positions[0]
	var best_distance: float = -1.0

	for candidate: Vector2 in spawn_positions:
		var nearest_distance: float = INF

		for light: PointLight2D in lights:
			if light == current_light:
				continue

			var distance: float = candidate.distance_to(
				light.position
			)

			if distance < nearest_distance:
				nearest_distance = distance

		if nearest_distance > best_distance:
			best_distance = nearest_distance
			best_position = candidate

	return best_position
