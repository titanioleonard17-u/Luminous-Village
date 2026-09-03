extends StaticBody2D

@onready var window_sprite: AnimatedSprite2D = $House_Sprite
@onready var light_node: Node2D = $WindowLight/TerraceLightNode
@onready var light_node2: Node2D = $WindowLight/BalconLightNode

var last_hit_frame: int = -10
var is_lit: bool = false
var is_celebrating: bool = false


func _ready() -> void:
	_set_lights_alpha(0.0)

func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return

	if is_celebrating:
		return

	_set_lit(is_currently_hit())


func mark_hit() -> void:
	last_hit_frame = Engine.get_physics_frames()


func is_currently_hit() -> bool:
	var current_frame: int = Engine.get_physics_frames()
	return (current_frame - last_hit_frame) <= 1


func _set_lit(should_light: bool) -> void:
	if should_light == is_lit:
		return

	is_lit = should_light

	if is_lit:
		light_node.modulate.a = 1.0
		light_node2.modulate.a = 1.0
		_squish()
	else:
		light_node.modulate.a = 0.0
		light_node2.modulate.a = 0.0


func celebrate() -> void:
	is_celebrating = true

	var point_lights: Array[PointLight2D] = []

	for lightNode in $WindowLight.get_children():
		if lightNode.name.contains("LightNode"):
			for pointLight in lightNode.get_children():
				if pointLight is PointLight2D:
					point_lights.append(pointLight)

	# Awal: semua lampu mati
	for pointLight in point_lights:
		pointLight.color.a = 0.0

	for i in range(3):
		if not is_celebrating:
			return

		# =========================
		# FADE IN: 0 -> 1
		# =========================
		var tween := create_tween()
		tween.set_parallel()

		for pointLight in point_lights:
			var color := pointLight.color
			color.a = 1.0

			tween.tween_property(
				pointLight,
				"color",
				color,
				0.35
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		await tween.finished

		if not is_celebrating:
			return

		# Sudah 100% terlihat -> POP
		AudioManager.playAudio("Pop", AudioManager.AudioType.SFX)
		_squish()

		# =========================
		# FADE OUT: 1 -> 0
		# =========================
		tween = create_tween()
		tween.set_parallel()

		for pointLight in point_lights:
			var color := pointLight.color
			color.a = 0.0

			tween.tween_property(
				pointLight,
				"color",
				color,
				0.35
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		await tween.finished

	is_celebrating = false

func stop_celebrate() -> void:
	is_celebrating = false

	light_node.modulate.a = 0.0
	light_node2.modulate.a = 0.0

	is_lit = false


func _squish() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	AudioManager.playAudio("Pop", AudioManager.AudioType.SFX)

	tween.tween_property(
		window_sprite,
		"scale",
		Vector2(0.59, 0.41),
		0.08
	)

	tween.tween_property(
		window_sprite,
		"scale",
		Vector2(0.46, 0.54),
		0.06
	)

	tween.tween_property(
		window_sprite,
		"scale",
		Vector2(0.5, 0.5),
		0.08
	)


func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)

func _set_lights_alpha(alpha: float) -> void:
	for lightNode in $WindowLight.get_children():
		if lightNode.name.contains("LightNode"):
			for pointLight in lightNode.get_children():
				if pointLight is PointLight2D:
					var color : Color = pointLight.color
					color.a = alpha
					pointLight.color = color
