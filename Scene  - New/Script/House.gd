extends StaticBody2D

@onready var window_sprite: AnimatedSprite2D = $House_Sprite
@onready var window_glow: Polygon2D = $WindowLight/Polygon2D
@onready var light_node: Node2D = $WindowLight/LightNode
@onready var light_node2: Node2D = $WindowLight/LightNode2

var last_hit_frame: int = -10
var is_lit: bool = false

func _ready() -> void:
	window_glow.visible = false
	light_node.visible = false
	light_node2.visible = false

func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		print("House _physics_process masih jalan walau paused!")
		return

	var current_frame: int = Engine.get_physics_frames()
	var is_hit: bool = (current_frame - last_hit_frame) <= 1
	_set_lit(is_hit)

func mark_hit() -> void:
	last_hit_frame = Engine.get_physics_frames()

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
	_squish()

func _squish() -> void:
	var tween := create_tween()
	tween.tween_property(window_sprite, "scale", Vector2(0.59, 0.41), 0.08)
	tween.tween_property(window_sprite, "scale", Vector2(0.46, 0.54), 0.06)
	tween.tween_property(window_sprite, "scale", Vector2(0.5, 0.5), 0.08)

func get_reflect_normal() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)
