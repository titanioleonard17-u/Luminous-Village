extends StaticBody2D

@onready var window_sprite: AnimatedSprite2D = $House_Sprite
@onready var light_node: Node2D = $WindowLight/TerraceLightNode
@onready var light_node2: Node2D = $WindowLight/BalconLightNode

@export var blink_count: int = 3
@export var blink_on_duration: float = 0.28
@export var blink_off_duration: float = 0.22
@export var lost_hit_grace_frames: int = 6

var last_hit_frame: int = -10
var is_lit: bool = false
var is_blinking: bool = false
var is_celebrating: bool = false

var blink_id: int = 0


func _ready() -> void:
	_set_lights_alpha(0.0)


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	if is_celebrating:
		return

	var hit: bool = is_currently_hit()

	if hit:
		if not is_lit:
			is_lit = true
			_squish()
	else:
		if is_lit and _lost_hit_beyond_grace():
			_turn_off()


func mark_hit() -> void:
	last_hit_frame = Engine.get_physics_frames()


func is_currently_hit() -> bool:
	var current_frame: int = Engine.get_physics_frames()
	return (current_frame - last_hit_frame) <= 1


func _lost_hit_beyond_grace() -> bool:
	var current_frame: int = Engine.get_physics_frames()
	return (current_frame - last_hit_frame) > lost_hit_grace_frames


func _turn_off() -> void:
	blink_id += 1
	is_blinking = false
	is_lit = false
	_set_lights_alpha(0.0)


func celebrate() -> void:
	is_celebrating = true
	blink_id += 1
	is_blinking = false

	await _squish()
	await _squish()
	await _squish()

	is_celebrating = false


func stop_celebrate() -> void:
	is_celebrating = false
	is_lit = false
	is_blinking = false
	blink_id += 1
	_set_lights_alpha(0.0)


func _squish() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	AudioManager.playAudio("Pop", AudioManager.AudioType.SFX)

	tween.tween_property(
		window_sprite,
		"scale",
		Vector2(0.56, 0.45),
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		window_sprite,
		"scale",
		Vector2(0.5, 0.5),
		0.20
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished


func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)


func _set_lights_alpha(alpha: float) -> void:
	light_node.modulate.a = alpha
	light_node2.modulate.a = alpha

	for lightNode in $WindowLight.get_children():
		if lightNode.name.contains("LightNode"):
			for pointLight in lightNode.get_children():
				if pointLight is PointLight2D:
					var color: Color = pointLight.color
					color.a = alpha
					pointLight.color = color


func night_blink() -> void:
	is_blinking = true

	for i in range(blink_count):
		_set_lights_alpha(1.0)
		await get_tree().create_timer(blink_on_duration, true).timeout

		_set_lights_alpha(0.0)
		await get_tree().create_timer(blink_off_duration, true).timeout

	is_blinking = false
	_set_lights_alpha(1.0)
