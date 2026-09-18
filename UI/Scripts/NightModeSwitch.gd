extends CanvasLayer

@export var area_size: Vector2 = Vector2(1280, 720)

# Ukuran light
@export var min_light_scale: float = 1.0
@export var max_light_scale: float = 3.0

# Kecepatan light
@export var min_speed: float = 20.0
@export var max_speed: float = 40.0

# Seberapa jauh light boleh keluar sebelum dipindahkan
@export var light_margin: float = 100.0

# Jarak minimum antar light saat spawn
@export var min_spawn_distance: float = 150.0

# Warna semua light
@export var light_color: Color = Color(1.0, 0.85, 0.3, 1.0)

# Opacity
@export_category("Opacity")
@export_range(0.0, 1.0) var min_opacity: float = 0.3
@export_range(0.0, 1.0) var max_opacity: float = 0.7
@export var min_opacity_speed: float = 0.15
@export var max_opacity_speed: float = 0.35

var lights: Array[PointLight2D] = []
var spawn_positions: Array[Vector2] = []

func _ready() -> void:
	randomize()

	_get_lights()
	_generate_spawn_positions()
	_setup_lights()

	print("JUMLAH LIGHT: ", lights.size())

func _process(delta: float) -> void:
	for light: PointLight2D in lights:
		_move_light(light, delta)
		_update_opacity(light, delta)

		if _is_outside(light):
			_respawn_light(light)

func _get_lights() -> void:
	lights.clear()

	for child: Node in $Container/LightNode.get_children():
		print(child.name, " | ", child.get_class())

		if child is PointLight2D:
			lights.append(child as PointLight2D)

func _generate_spawn_positions() -> void:
	spawn_positions.clear()

	var light_count: int = lights.size()

	if light_count == 0:
		return

	var attempts: int = 0
	var max_attempts: int = 1000

	while spawn_positions.size() < light_count and attempts < max_attempts:
		attempts += 1

		var new_position := Vector2(
			randf_range(50.0, area_size.x - 50.0),
			randf_range(50.0, area_size.y - 50.0)
		)

		var valid: bool = true

		for existing_position: Vector2 in spawn_positions:
			if new_position.distance_to(existing_position) < min_spawn_distance:
				valid = false
				break

		if valid:
			spawn_positions.append(new_position)

	if spawn_positions.size() < light_count:
		push_warning(
			"Tidak semua posisi light berhasil dibuat karena min_spawn_distance terlalu besar."
		)

func _setup_lights() -> void:
	for i in range(lights.size()):
		var light: PointLight2D = lights[i]

		if i < spawn_positions.size():
			light.position = spawn_positions[i]

		var light_scale: float = randf_range(
			min_light_scale,
			max_light_scale
		)

		light.scale = Vector2.ONE * light_scale

		var opacity: float = randf_range(
			min_opacity,
			max_opacity
		)

		light.color = Color(
			light_color.r,
			light_color.g,
			light_color.b,
			opacity
		)

		light.set_meta(
			"speed",
			randf_range(min_speed, max_speed)
		)

		var direction := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		light.set_meta(
			"direction",
			direction
		)

		light.set_meta(
			"light_scale",
			light_scale
		)

		light.set_meta(
			"opacity",
			opacity
		)

		light.set_meta(
			"opacity_speed",
			randf_range(
				min_opacity_speed,
				max_opacity_speed
			)
		)

		light.set_meta(
			"opacity_direction",
			1.0 if randf() > 0.5 else -1.0
		)

func _move_light(light: PointLight2D, delta: float) -> void:
	var direction: Vector2 = light.get_meta("direction")
	var speed: float = light.get_meta("speed")

	light.global_position += direction * speed * delta

	# Perubahan arah kecil secara random
	if randf() < 0.015:
		var new_direction := direction.rotated(
			randf_range(-0.35, 0.35)
		)

		light.set_meta(
			"direction",
			new_direction.normalized()
		)

func _update_opacity(light: PointLight2D, delta: float) -> void:
	var opacity: float = light.get_meta("opacity")
	var opacity_speed: float = light.get_meta("opacity_speed")
	var opacity_direction: float = light.get_meta("opacity_direction")

	opacity += opacity_direction * opacity_speed * delta

	if opacity >= max_opacity:
		opacity = max_opacity
		opacity_direction = -1.0

	elif opacity <= min_opacity:
		opacity = min_opacity
		opacity_direction = 1.0

	light.set_meta(
		"opacity",
		opacity
	)

	light.set_meta(
		"opacity_direction",
		opacity_direction
	)

	var color: Color = light.color
	color.a = opacity
	light.color = color

func _is_outside(light: PointLight2D) -> bool:
	var light_scale: float = light.get_meta(
		"light_scale",
		1.0
	)

	var margin: float = light_margin * light_scale
	var pos := light.global_position

	return (
		pos.x < -margin
		or pos.x > area_size.x + margin
		or pos.y < -margin
		or pos.y > area_size.y + margin
	)

func _respawn_light(light: PointLight2D) -> void:
	var new_position: Vector2 = _get_best_spawn_position(light)

	light.global_position = new_position

	light.set_meta(
		"speed",
		randf_range(
			min_speed,
			max_speed
		)
	)

	var new_direction := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	light.set_meta(
		"direction",
		new_direction
	)

func _get_best_spawn_position(
	current_light: PointLight2D
) -> Vector2:

	if spawn_positions.is_empty():
		return Vector2.ZERO

	var best_position: Vector2 = spawn_positions[0]
	var best_distance: float = -1.0

	for candidate: Vector2 in spawn_positions:
		var nearest_distance: float = INF

		for light: PointLight2D in lights:
			if light == current_light:
				continue

			var distance := candidate.distance_to(
				light.global_position
			)

			if distance < nearest_distance:
				nearest_distance = distance

		if nearest_distance > best_distance:
			best_distance = nearest_distance
			best_position = candidate

	return best_position
