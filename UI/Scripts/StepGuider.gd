extends Control


# =========================================================
# CHARACTER
# =========================================================

@onready var character_texture: TextureRect = $TextureRect
@onready var animated_texture: AnimatedTexture = character_texture.texture


# =========================================================
# ANIMATION
# =========================================================

@export_category("Squish Animation")

@export var normal_scale := Vector2(1.0, 1.0)
@export var squash_scale := Vector2(1.12, 0.88)
@export var stretch_scale := Vector2(0.92, 1.08)

@export var squash_duration := 0.08
@export var stretch_duration := 0.08
@export var return_duration := 0.1


# =========================================================
# VARIABLES
# =========================================================

var animation_tween: Tween


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	character_texture.scale = normal_scale

	if animated_texture:
		animated_texture.pause = true
	
	change_costume(2)
	await get_tree().create_timer(2.0).timeout
	change_costume(3)
	await get_tree().create_timer(2.0).timeout
	change_costume(1)


# =========================================================
# CHANGE COSTUME
# =========================================================

func change_costume(index: int) -> void:
	if animated_texture == null:
		return

	if index < 1:
		return

	var frame_index := index - 1

	if frame_index >= animated_texture.frames:
		return

	animated_texture.current_frame = frame_index
	
	play_squish_animation()

# =========================================================
# SQUISH ANIMATION
# =========================================================

func play_squish_animation() -> void:
	if animation_tween:
		animation_tween.kill()

	character_texture.scale = normal_scale

	animation_tween = create_tween()

	animation_tween.set_trans(Tween.TRANS_BACK)
	animation_tween.set_ease(Tween.EASE_OUT)

	# Squish
	animation_tween.tween_property(
		character_texture,
		"scale",
		squash_scale,
		squash_duration
	)

	# Stretch
	animation_tween.tween_property(
		character_texture,
		"scale",
		stretch_scale,
		stretch_duration
	)

	# Normal
	animation_tween.tween_property(
		character_texture,
		"scale",
		normal_scale,
		return_duration
	)
