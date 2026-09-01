extends Node2D

@export var win_label_path: NodePath
@export var btn_level_select_path: NodePath
@export var btn_next_level_path: NodePath
@export var level_select_scene: String = "res://Asset/Art/LevelSelection.tscn"  # sesuaikan path scene-mu
@export var next_level_scene: String = ""  # isi per-level di Inspector, misal "res://Level2.tscn"

var level_complete: bool = false
var is_celebrating_win: bool = false
var win_label: Node = null
var btn_level_select: Button = null
var btn_next_level: Button = null
var celebration_id: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_complete = false

	if not win_label_path.is_empty():
		win_label = get_node(win_label_path)
		win_label.visible = false
		win_label.process_mode = Node.PROCESS_MODE_ALWAYS

	if not btn_level_select_path.is_empty():
		btn_level_select = get_node(btn_level_select_path)
		btn_level_select.visible = false
		btn_level_select.process_mode = Node.PROCESS_MODE_ALWAYS
		btn_level_select.pressed.connect(_on_level_select_pressed)
		btn_level_select.button_down.connect(_squish_button.bind(btn_level_select))
		_strip_button_style(btn_level_select)

	if not btn_next_level_path.is_empty():
		btn_next_level = get_node(btn_next_level_path)
		btn_next_level.visible = false
		btn_next_level.process_mode = Node.PROCESS_MODE_ALWAYS
		btn_next_level.pressed.connect(_on_next_level_pressed)
		btn_next_level.button_down.connect(_squish_button.bind(btn_next_level))
		_strip_button_style(btn_next_level)

func _strip_button_style(btn: Button) -> void:
	# Hilangkan background kotak/hitam bawaan Button, biar cuma icon/teksnya aja yang keliatan
	var empty_style := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.add_theme_stylebox_override("disabled", empty_style)
	# Kalau kamu pasang gambar di properti Icon, biar gambarnya ngisi penuh tombol:
	btn.expand_icon = true

func _squish_button(btn: Button) -> void:
	# Kompensasi posisi manual biar tombol gak "maju"/geser pas di-scale
	# (gak pakai pivot_offset karena ganggu posisi awal animasi drop)
	var base_pos: Vector2 = btn.position
	var half_size: Vector2 = btn.size / 2.0

	var s1 := Vector2(0.85, 0.75)
	var s2 := Vector2(1.08, 0.92)
	var s3 := Vector2(1.0, 1.0)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween.tween_property(btn, "scale", s1, 0.08)
	tween.parallel().tween_property(btn, "position", base_pos - (s1 - Vector2.ONE) * half_size, 0.08)

	tween.tween_property(btn, "scale", s2, 0.06)
	tween.parallel().tween_property(btn, "position", base_pos - (s2 - Vector2.ONE) * half_size, 0.06)

	tween.tween_property(btn, "scale", s3, 0.08)
	tween.parallel().tween_property(btn, "position", base_pos, 0.08)

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
	print("PAUSED STATUS: ", get_tree().paused)

	if win_label:
		win_label.visible = true
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		win_label.modulate.a = 0.0
		tween.tween_property(win_label, "modulate:a", 1.0, 0.6)
		tween.tween_callback(_show_buttons)

func _show_buttons() -> void:
	_animate_button_drop(btn_level_select)
	_animate_button_drop(btn_next_level)

func _animate_button_drop(btn: Button) -> void:
	if btn == null:
		return
	btn.visible = true
	btn.modulate.a = 0.0

	var target_pos: Vector2 = btn.position

	# Mulai dari atas label COMPLETE: X tetap punya tombol, Y ambil dari label
	var start_pos: Vector2 = target_pos
	if win_label:
		start_pos.y = win_label.position.y

	btn.position = start_pos

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(btn, "position", target_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate:a", 1.0, 0.4)

func _on_level_select_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(level_select_scene)

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
