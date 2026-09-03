extends StaticBody2D

@onready var window_sprite: AnimatedSprite2D = $House_Sprite
@onready var light_node: Node2D = $WindowLight/TerraceLightNode
@onready var light_node2: Node2D = $WindowLight/BalconLightNode

@export var blink_count: int = 3
@export var blink_on_duration: float = 0.28   # lama nyala tiap kedip
@export var blink_off_duration: float = 0.22  # lama mati tiap kedip
@export var lost_hit_grace_frames: int = 6    # toleransi berapa physics frame boleh "gak kena" sebelum dianggap sinar hilang beneran

var last_hit_frame: int = -10
var is_lit: bool = false          # status nyala solid (final)
var is_blinking: bool = false     # lagi proses kedip menyala
var is_celebrating: bool = false

var blink_id: int = 0             # token buat cancel proses blink kalau sinar hilang di tengah jalan


func _ready() -> void:
	_set_lights_alpha(0.0)


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	if is_celebrating:
		return

	var hit: bool = is_currently_hit()

	if hit:
		if not is_lit and not is_blinking:
			_start_blink_then_lit()
	else:
		# Hanya matikan kalau sinar SUDAH hilang lebih lama dari grace period,
		# biar glitch 1 frame (mis. laser lagi geser di mirror/prism) gak bikin
		# rumah yang udah nyala ikutan kedip ulang.
		if (is_lit or is_blinking) and _lost_hit_beyond_grace():
			_turn_off()


func mark_hit() -> void:
	last_hit_frame = Engine.get_physics_frames()


func is_currently_hit() -> bool:
	var current_frame: int = Engine.get_physics_frames()
	return (current_frame - last_hit_frame) <= 1


func _lost_hit_beyond_grace() -> bool:
	var current_frame: int = Engine.get_physics_frames()
	return (current_frame - last_hit_frame) > lost_hit_grace_frames


func _start_blink_then_lit() -> void:
	is_blinking = true
	blink_id += 1
	var my_id: int = blink_id

	for i in range(blink_count):
		if my_id != blink_id or is_celebrating:
			return
		_set_lights_alpha(1.0)
		_squish()
		await get_tree().create_timer(blink_on_duration, true).timeout
		if my_id != blink_id or is_celebrating:
			return
		_set_lights_alpha(0.0)
		await get_tree().create_timer(blink_off_duration, true).timeout

	if my_id != blink_id or is_celebrating:
		return

	is_blinking = false
	is_lit = true
	_set_lights_alpha(1.0)
	_squish()


func _turn_off() -> void:
	blink_id += 1
	is_blinking = false
	is_lit = false
	_set_lights_alpha(0.0)


func celebrate() -> void:
	is_celebrating = true
	blink_id += 1
	is_blinking = false

	# Rumah tetap nyala terang, cukup 1x pop sebagai penekanan,
	# tidak perlu kedip 3x lagi seperti proses awal.
	_set_lights_alpha(1.0)
	AudioManager.playAudio("Pop", AudioManager.AudioType.SFX)
	_squish()

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
	light_node.modulate.a = alpha
	light_node2.modulate.a = alpha
	for lightNode in $WindowLight.get_children():
		if lightNode.name.contains("LightNode"):
			for pointLight in lightNode.get_children():
				if pointLight is PointLight2D:
					var color: Color = pointLight.color
					color.a = alpha
					pointLight.color = color
