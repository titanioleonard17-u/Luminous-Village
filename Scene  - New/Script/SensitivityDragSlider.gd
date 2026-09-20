extends Node2D

signal value_changed(value: float)

@export var track_length: float = 300.0
@export var min_value: float = 1.0
@export var max_value: float = 200.0
@export var default_value: float = 100.0
@export var invert: bool = true

@export var hit_width: float = 80.0
@export var hit_padding: float = 20.0

@export var mirror_target_path: NodePath
var mirror_target: Node = null

var is_step_guide_active: bool = false
var is_dragging: bool = false
var touch_index: int = -1
var current_value: float = 0.5

@onready var handle: Sprite2D = $Handle

const SAVE_PATH := "user://sensitivity.cfg"
const SAVE_SECTION := "settings"
const SAVE_KEY := "sensitivity_norm" # posisi relatif 0..1, aman kalau min/max diubah

func _ready() -> void:
	add_to_group("sensitivity_slider") # supaya bisa dicari lewat group, bukan path
	current_value = default_value
	_load_saved_sensitivity()
	_update_handle_position()
	print("Slider mulai di value = ", current_value, " (default = ", default_value, ")")

	if mirror_target_path != NodePath(""):
		mirror_target = get_node_or_null(mirror_target_path)

	# Deferred: pastikan semua node di level sudah masuk group "sensitivity_target"
	# sebelum value-nya di-broadcast.
	_apply_sensitivity_to_mirror.call_deferred()

func _input(event: InputEvent) -> void:
	if is_step_guide_active:
		return
	
	if get_tree().paused:
		return

	# --- Mouse ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not is_dragging and _is_point_over(_viewport_to_local(event.position)):
				_start_drag()
				_drag_to(_viewport_to_local(event.position))
				get_viewport().set_input_as_handled()
		elif is_dragging:
			_end_drag()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		_drag_to(_viewport_to_local(event.position))
		get_viewport().set_input_as_handled()

	# --- Touch ---
	elif event is InputEventScreenTouch:
		if event.pressed:
			if not is_dragging and _is_point_over(_viewport_to_local(event.position)):
				touch_index = event.index
				_start_drag()
				_drag_to(_viewport_to_local(event.position))
				get_viewport().set_input_as_handled()
		elif is_dragging and event.index == touch_index:
			touch_index = -1
			_end_drag()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		_drag_to(_viewport_to_local(event.position))
		get_viewport().set_input_as_handled()

# Konversi posisi event (koordinat viewport) ke koordinat lokal slider.
# Sudah memperhitungkan transform CanvasLayer, jadi aman walau kamera zoom/geser.
func _viewport_to_local(viewport_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_pos

func _start_drag() -> void:
	is_dragging = true

func _end_drag() -> void:
	is_dragging = false
	_save_sensitivity()

func _drag_to(local_pos: Vector2) -> void:
	var half: float = track_length * 0.5
	var local_y: float = clamp(local_pos.y, -half, half)

	var t: float = (local_y + half) / track_length
	if not invert:
		t = 1.0 - t

	current_value = lerp(min_value, max_value, t)
	_update_handle_position()
	value_changed.emit(current_value)
	_apply_sensitivity_to_mirror()

func _apply_sensitivity_to_mirror() -> void:
	# Broadcast ke SEMUA node yang bisa diputar (Mirror, Prism, Trigger, dst),
	# termasuk yang di-spawn dinamis -- otomatis kena tanpa perlu assign manual.
	get_tree().call_group("sensitivity_target", "set_sensitivity", current_value, max_value)

	# Tetap dukung target tunggal lama (kalau masih dipakai di suatu tempat), gak masalah dobel.
	if mirror_target != null and mirror_target.has_method("set_sensitivity"):
		mirror_target.set_sensitivity(current_value, max_value)

func _update_handle_position() -> void:
	var half: float = track_length * 0.5
	var t: float = (current_value - min_value) / (max_value - min_value)
	if not invert:
		t = 1.0 - t
	var local_y: float = lerp(-half, half, t)
	handle.position.y = local_y

# Hit-test manual: area persegi di sekitar track (tanpa physics / collision).
func _is_point_over(local_pos: Vector2) -> bool:
	var half: float = track_length * 0.5
	var rect := Rect2(
		Vector2(-hit_width * 0.5, -half - hit_padding),
		Vector2(hit_width, track_length + hit_padding * 2.0)
	)
	return rect.has_point(local_pos)

func get_value() -> float:
	return current_value

func set_value(v: float) -> void:
	current_value = clamp(v, min_value, max_value)
	_update_handle_position()
	_apply_sensitivity_to_mirror()

func set_mirror_target(target: Node) -> void:
	mirror_target = target
	_apply_sensitivity_to_mirror()

func _save_sensitivity() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, SAVE_KEY, inverse_lerp(min_value, max_value, current_value))
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Gagal save sensitivity: " + str(err))

func _load_saved_sensitivity() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return # belum pernah ke-save, pakai default_value

	var norm: float = cfg.get_value(SAVE_SECTION, SAVE_KEY, -1.0)
	if norm < 0.0 or norm > 1.0:
		return # belum ada data valid, pakai default_value
	current_value = lerp(min_value, max_value, norm)

func set_step_guide_status(value: bool) -> void:
	is_step_guide_active = value
