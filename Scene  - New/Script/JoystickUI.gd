extends Node2D
class_name JoystickUI

@export var ring_texture: Texture2D

@export var ring_display_radius: float = 100.0
@export var ball_orbit_radius: float = 78.0
@export var ball_display_radius: float = 18.0

@export var ball_fill_color: Color = Color(1.0, 0.95, 0.78, 1.0)
@export var ball_border_color: Color = Color(0.75, 0.55, 0.25, 1.0)
@export var ball_border_width: float = 4.0

var ring_sprite: Sprite2D
var ball_node: Node2D

var current_angle: float = 0.0

func _ready() -> void:
	ring_sprite = Sprite2D.new()
	ring_sprite.texture = ring_texture
	ring_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ring_sprite.z_index = 0
	add_child(ring_sprite)
	_fit_sprite_to_radius(ring_sprite, ring_display_radius)

	ball_node = Node2D.new()
	ball_node.z_index = 10
	add_child(ball_node)

	set_angle(current_angle)
	queue_redraw()

func _fit_sprite_to_radius(sprite: Sprite2D, target_radius: float) -> void:
	var tex_size: Vector2 = sprite.texture.get_size()
	var original_radius: float = tex_size.x / 2.0
	var scale_factor: float = target_radius / original_radius
	sprite.scale = Vector2(scale_factor, scale_factor)

func set_angle(angle_rad: float) -> void:
	current_angle = angle_rad
	if ball_node:
		ball_node.position = Vector2.RIGHT.rotated(current_angle) * ball_orbit_radius
		queue_redraw()

func _draw() -> void:
	if ball_node:
		var ball_pos: Vector2 = ball_node.position
		draw_circle(ball_pos, ball_display_radius, ball_fill_color)
		draw_arc(ball_pos, ball_display_radius, 0, TAU, 32, ball_border_color, ball_border_width, true)
