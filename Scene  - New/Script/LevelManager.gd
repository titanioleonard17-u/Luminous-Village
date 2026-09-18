extends Node2D

@export var level_complete_path: NodePath

@export_category("Animasi")
@export var slide_in_offset_y: float = 800.0
@export var sign_rise_offset: Vector2 = Vector2(0, -100)
@export var hold_duration: float = 1.2

@export_category("Win Delay")
@export var night_delay: float = 0.5
@export var win_delay: float = 0.6

@export var next_level_scene: String = ""

var level_complete: bool = false
var is_celebrating_win: bool = false
var is_switching_night: bool = false
var celebration_id: int = 0

var bg: Control = null
var sign: Control = null
var back_button: TextureButton = null
var next_button: TextureButton = null

var bg_target_pos: Vector2
var sign_center_pos: Vector2
var back_target_pos: Vector2
var next_target_pos: Vector2


func _ready() -> void:
	if get_tree().current_scene.name.contains("TutorialLevel"):
		$PauseTriger/GuideMenu.visible = true

	AudioManager.playRandomVibe()

	process_mode = Node.PROCESS_MODE_ALWAYS
	level_complete = false

	$LevelComplete.visible = false
	$NightModeSwitch.visible = false
	$NightModulate.visible = false

	if level_complete_path.is_empty():
		push_warning("level_complete_path belum diisi di Inspector!")
		return

	var lc := get_node_or_null(level_complete_path)

	if lc == null:
		push_error("LevelComplete tidak ditemukan dari level_complete_path!")
		return

	bg = lc.find_child("Bg", true, false) as Control
	sign = lc.find_child("Complete_Sign", true, false) as Control
	back_button = lc.find_child("Back_Button", true, false) as TextureButton
	next_button = lc.find_child("Next_Button", true, false) as TextureButton

	print("=== LEVEL COMPLETE SETUP ===")
	print("LevelComplete: ", lc)
	print("BG: ", bg)
	print("SIGN: ", sign)
	print("BACK: ", back_button)
	print("NEXT: ", next_button)

	if bg:
		bg.process_mode = Node.PROCESS_MODE_ALWAYS
		bg_target_pos = bg.position
		bg.visible = false
	else:
		push_warning("Bg tidak ditemukan!")

	if sign:
		sign.process_mode = Node.PROCESS_MODE_ALWAYS
		sign_center_pos = sign.position
		sign.visible = false
	else:
		push_warning("Complete_Sign tidak ditemukan!")

	if back_button:
		back_button.process_mode = Node.PROCESS_MODE_ALWAYS
		back_target_pos = back_button.position
		back_button.visible = false
	else:
		push_warning("Back_Button tidak ditemukan!")

	if next_button:
		next_button.process_mode = Node.PROCESS_MODE_ALWAYS
		next_target_pos = next_button.position
		next_button.visible = false

		if not next_button.pressed.is_connected(_on_next_level_pressed):
			next_button.pressed.connect(_on_next_level_pressed)
	else:
		push_warning("Next_Button tidak ditemukan!")


func _process(_delta: float) -> void:
	if level_complete or is_celebrating_win:
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

		if not house.is_currently_hit():
			return false

	return true


func _trigger_win() -> void:
	is_celebrating_win = true
	celebration_id += 1

	var my_id: int = celebration_id

	var lasers: Array = get_tree().get_nodes_in_group("laser")
	var houses: Array = get_tree().get_nodes_in_group("house")

	for laser in lasers:
		laser.visible = false

	# Semua rumah mulai celebrate bersamaan
	for house in houses:
		if house.has_method("celebrate"):
			house.celebrate()

	if my_id != celebration_id or not is_celebrating_win:
		return

	# Cek lagi apakah semua rumah masih disorot
	if not _all_houses_lit():
		is_celebrating_win = false

		for house in houses:
			if house.has_method("stop_celebrate"):
				house.stop_celebrate()

		return

	_lock_mirrors()

	# Jeda manual sebelum Night Mode
	await get_tree().create_timer(night_delay, true).timeout

	if my_id != celebration_id or not is_celebrating_win:
		return

	await _switch_to_night()

	if my_id != celebration_id or not is_celebrating_win:
		return

	# Nyalakan semua lampu rumah
	for house in houses:
		if house.has_method("turn_on_lights"):
			house.turn_on_lights()

	# Jeda sebelum Level Complete
	await get_tree().create_timer(win_delay, true).timeout

	if my_id != celebration_id or not is_celebrating_win:
		return

	level_complete = true
	is_celebrating_win = false

	get_tree().paused = true

	if get_tree().current_scene.name == "TutorialLevel" and not SaveManager.is_tutorial_completed():
		SaveManager.complete_tutorial()
	else:
		SaveManager.complete_level(get_tree().current_scene.name)

	AudioManager.playImportantSFX("LevelComplete")

	await get_tree().create_timer(2.0, true).timeout

	print("=== MENAMPILKAN LEVEL COMPLETE ===")

	$LevelComplete.visible = true

	print("LevelComplete visible: ", $LevelComplete.visible)

	_play_complete_sequence()


func _show_night() -> void:
	$NightModulate.color = Color(1, 1, 1, 1)

	var tween := create_tween()

	tween.tween_property(
		$NightModulate,
		"color",
		Color(0.15, 0.15, 0.25, 1.0),
		1.0
	)

	await tween.finished


func _switch_to_night() -> void:
	if is_switching_night:
		return

	is_switching_night = true

	$NightModulate.visible = true

	await _show_night()

	$PauseTriger.enable_night_mode()
	$NightModeSwitch.visible = true


func _lock_mirrors() -> void:
	var mirrors: Array = get_tree().get_nodes_in_group("mirror")

	for mirror in mirrors:
		if mirror.has_method("set_locked"):
			mirror.set_locked(true)


func _play_complete_sequence() -> void:
	print("=== PLAY COMPLETE SEQUENCE ===")

	if bg:
		bg.visible = true
		bg.position = bg_target_pos + Vector2(0, slide_in_offset_y)

	if sign:
		sign.visible = true
		sign.position = sign_center_pos + Vector2(0, slide_in_offset_y)

	if bg or sign:
		var tween_in := create_tween()
		tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_in.set_parallel(true)

		if bg:
			tween_in.tween_property(
				bg,
				"position",
				bg_target_pos,
				0.5
			).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		if sign:
			tween_in.tween_property(
				sign,
				"position",
				sign_center_pos,
				0.5
			).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await tween_in.finished

	await get_tree().create_timer(hold_duration, true).timeout

	if back_button:
		back_button.position = sign_center_pos
		back_button.visible = true
		back_button.modulate.a = 0.0

	if next_button:
		next_button.position = sign_center_pos
		next_button.visible = true
		next_button.modulate.a = 0.0

	if sign or back_button or next_button:
		var tween_out := create_tween()
		tween_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_out.set_parallel(true)

		if sign:
			tween_out.tween_property(
				sign,
				"position",
				sign_center_pos + sign_rise_offset,
				0.5
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		if back_button:
			tween_out.tween_property(
				back_button,
				"position",
				back_target_pos,
				0.45
			).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

			tween_out.tween_property(
				back_button,
				"modulate:a",
				1.0,
				0.25
			)

		if next_button:
			tween_out.tween_property(
				next_button,
				"position",
				next_target_pos,
				0.45
			).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

			tween_out.tween_property(
				next_button,
				"modulate:a",
				1.0,
				0.25
			)

		await tween_out.finished

	print("=== COMPLETE SEQUENCE SELESAI ===")


func _on_next_level_pressed() -> void:
	get_tree().paused = false

	if next_level_scene.is_empty():
		push_warning("next_level_scene belum diisi!")
		return

	get_tree().change_scene_to_file(next_level_scene)
