extends Node2D

@export var level_complete_path: NodePath   # drag node "LevelComplete" instance ke sini

@export_category("Animasi")
@export var slide_in_offset_y: float = 800.0   # seberapa jauh Bg & Sign mulai dari bawah layar
@export var sign_rise_offset: Vector2 = Vector2(0, -250)  # posisi Complete_Sign setelah naik ke atas
@export var hold_duration: float = 1.2         # jeda sebelum sign naik & tombol turun

@export var next_level_scene: String = ""

var level_complete: bool = false
var is_celebrating_win: bool = false
var celebration_id: int = 0

var bg: Control = null
var sign: Control = null
var back_button: TextureButton = null
var next_button: TextureButton = null

# posisi asli (dari editor) sebagai posisi target/final
var bg_target_pos: Vector2
var sign_center_pos: Vector2   # posisi tengah sign SEBELUM naik
var back_target_pos: Vector2
var next_target_pos: Vector2

func _ready() -> void:
	AudioManager.playRandomVibe()
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_complete = false

	if level_complete_path.is_empty():
		push_warning("level_complete_path belum diisi di Inspector!")
		return

	var lc := get_node(level_complete_path)

	# Pakai Unique Name (%Bg, %Complete_Sign, dst) yang sudah diset di LevelComplete.tscn.
	# Kalau belum sempat set unique name, ini fallback ke nama biasa.
	bg = lc.get_node_or_null("%Bg")
	if bg == null:
		bg = lc.get_node_or_null("Bg")

	sign = lc.get_node_or_null("%Complete_Sign")
	if sign == null:
		sign = lc.get_node_or_null("Complete_Sign")

	back_button = lc.get_node_or_null("%Back_Button")
	if back_button == null:
		back_button = lc.get_node_or_null("Back_Button")

	next_button = lc.get_node_or_null("%Next_Button")
	if next_button == null:
		next_button = lc.get_node_or_null("Next_Button")

	if bg:
		bg.process_mode = Node.PROCESS_MODE_ALWAYS
		bg_target_pos = bg.position
		bg.visible = false

	if sign:
		sign.process_mode = Node.PROCESS_MODE_ALWAYS
		sign_center_pos = sign.position
		sign.visible = false

	if back_button:
		back_button.process_mode = Node.PROCESS_MODE_ALWAYS
		back_target_pos = back_button.position
		back_button.visible = false

	if next_button:
		next_button.process_mode = Node.PROCESS_MODE_ALWAYS
		next_target_pos = next_button.position
		next_button.visible = false
		next_button.pressed.connect(_on_next_level_pressed)

func _process(_delta: float) -> void:
	if level_complete:
		return
	if is_celebrating_win:
		if not _all_houses_currently_hit():
			_cancel_celebration()
		return
	if _all_houses_lit():
		_trigger_win()

func _all_houses_lit() -> bool:
	var houses: Array = get_tree().get_nodes_in_group("house")
	if houses.is_empty():
		return false
	for house in houses:
		if not house.is_lit:
			return false
	return true

func _all_houses_currently_hit() -> bool:
	var houses: Array = get_tree().get_nodes_in_group("house")
	if houses.is_empty():
		return false
	for house in houses:
		if not house.is_currently_hit():
			return false
	return true

func _trigger_win() -> void:
	is_celebrating_win = true
	celebration_id += 1
	var my_id: int = celebration_id

	print("Semua rumah nyala! Mulai kedip perayaan. id=", my_id)

	var lasers: Array = get_tree().get_nodes_in_group("laser")
	for laser in lasers:
		laser.visible = false

	var houses: Array = get_tree().get_nodes_in_group("house")
	for house in houses:
		if house.has_method("celebrate"):
			house.celebrate()

	await get_tree().create_timer(2.3, true).timeout

	if my_id != celebration_id or not is_celebrating_win:
		return

	level_complete = true
	get_tree().paused = true

	AudioManager.playImportantSFX("LevelComplete")
	_play_complete_sequence()

func _play_complete_sequence() -> void:
	# --- Tahap 1: Bg & Complete_Sign naik bareng dari bawah layar ---
	if bg:
		bg.visible = true
		bg.position = bg_target_pos + Vector2(0, slide_in_offset_y)
	if sign:
		sign.visible = true
		sign.position = sign_center_pos + Vector2(0, slide_in_offset_y)

	var tween_in := create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.set_parallel(true)

	if bg:
		tween_in.tween_property(bg, "position", bg_target_pos, 0.5)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if sign:
		tween_in.tween_property(sign, "position", sign_center_pos, 0.5)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween_in.finished

	# --- Tahap 2: tahan sebentar di tengah ---
	await get_tree().create_timer(hold_duration, true).timeout

	# --- Tahap 3: Sign naik ke atas, Back & Next turun "dari dalam" Sign ---
	if back_button:
		back_button.position = sign_center_pos
		back_button.visible = true
		back_button.modulate.a = 0.0
	if next_button:
		next_button.position = sign_center_pos
		next_button.visible = true
		next_button.modulate.a = 0.0

	var tween_out := create_tween()
	tween_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_out.set_parallel(true)

	if sign:
		tween_out.tween_property(sign, "position", sign_center_pos + sign_rise_offset, 0.5)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if back_button:
		tween_out.tween_property(back_button, "position", back_target_pos, 0.45)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_out.tween_property(back_button, "modulate:a", 1.0, 0.25)

	if next_button:
		tween_out.tween_property(next_button, "position", next_target_pos, 0.45)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_out.tween_property(next_button, "modulate:a", 1.0, 0.25)

func _on_next_level_pressed() -> void:
	get_tree().paused = false
	if next_level_scene.is_empty():
		print("next_level_scene belum diisi di Inspector untuk level ini!")
		return
	get_tree().change_scene_to_file(next_level_scene)

func _cancel_celebration() -> void:
	print("Rumah lepas dari laser, batalkan perayaan & nyalakan laser lagi.")
	is_celebrating_win = false
	celebration_id += 1

	var houses: Array = get_tree().get_nodes_in_group("house")
	for house in houses:
		if house.has_method("stop_celebrate"):
			house.stop_celebrate()

	var lasers: Array = get_tree().get_nodes_in_group("laser")
	for laser in lasers:
		laser.visible = true
