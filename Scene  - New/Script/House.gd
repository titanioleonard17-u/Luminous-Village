extends StaticBody2D

@onready var window_sprite: AnimatedSprite2D = $House_Sprite
@onready var window_glow: Polygon2D = $WindowLight/Polygon2D
@onready var light_node: Node2D = $WindowLight/LightNode
@onready var light_node2: Node2D = $WindowLight/LightNode2

var last_hit_frame: int = -10
var is_lit: bool = false
var is_celebrating: bool = false

func _ready() -> void:
	window_glow.visible = false
	light_node.visible = false
	light_node2.visible = false

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
	window_glow.visible = is_lit
	light_node.visible = is_lit
	light_node2.visible = is_lit
	if is_lit:
		_squish()

func celebrate() -> void:
	is_celebrating = true
	for i in range(3):
		if not is_celebrating:
			return
		_set_lights_visible(false)
		await get_tree().create_timer(0.35, true).timeout
		if not is_celebrating:
			return
		_set_lights_visible(true)
		_squish()
		await get_tree().create_timer(0.35, true).timeout
	if not is_celebrating:
		return
	_set_lights_visible(true)
	is_celebrating = false

func stop_celebrate() -> void:
	is_celebrating = false
	_set_lights_visible(false)
	is_lit = false

func _set_lights_visible(value: bool) -> void:
	window_glow.visible = value
	light_node.visible = value
	light_node2.visible = value

func _squish() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(window_sprite, "scale", Vector2(0.59, 0.41), 0.08)
	tween.tween_property(window_sprite, "scale", Vector2(0.46, 0.54), 0.06)
	tween.tween_property(window_sprite, "scale", Vector2(0.5, 0.5), 0.08)

func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)
