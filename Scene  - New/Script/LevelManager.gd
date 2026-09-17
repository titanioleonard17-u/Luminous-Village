extends Node2D

@export var level_complete_path: NodePath

@export_category("Animasi")
@export var slide_in_offset_y: float = 800.0
@export var sign_rise_offset: Vector2 = Vector2(0, -100)
@export var hold_duration: float = 1.2

@export_category("Win Delay")
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
		$Container/PauseTriger/GuideMenu.visible = true

	AudioManager.playRandomVibe()
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_complete = false

	$Container/LevelComplete.visible = false
	$Container/ModeAnimation.visible = false

	if level_complete_path.is_empty():
		push_warning("level_complete_path belum diisi di Inspector!")
		return

	var lc := get_node(level_complete_path)

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

	return true

func _trigger_win() -> void:
	is_celebrating_win = true
	celebration_id += 1

	var my_id: int = celebration_id

	var lasers: Array = get_tree().get_nodes_in_group("laser")

	for laser in lasers:
		laser.visible = false

	var houses: Array = get_tree().get_nodes_in_group("house")

	for house in houses:
		if house.has_method("celebrate"):
			house.celebrate()

	await get_tree().create_timer(0.7, true).timeout

	if my_id != celebration_id or not is_celebrating_win:
		return

	await get_tree().create_timer(0.5, true).timeout

	if my_id != celebration_id or not is_celebrating_win:
		return

	_lock_mirrors()

	await _switch_to_night()

	if my_id != celebration_id or not is_celebrating_win:
		return

	for house in houses:
		if house.has_method("turn_on_lights"):
			house.turn_on_lights()

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

	await get_tree().create_timer(2.0).timeout
	$Container/LevelComplete.visible = true
	_play_complete_sequence()

func _switch_to_night() -> void:
	if is_switching_night:
		return

	is_switching_night = true

	var animation_player := $Container/ModeAnimation/AnimationPlayer

	$Container/ModeAnimation.visible = true

	animation_player.stop()
	animation_player.seek(0.0, true)
	animation_player.play("SwitchModeNight")

	await animation_player.animation_finished

func _lock_mirrors() -> void:
	var mirrors: Array = get_tree().get_nodes_in_group("mirror")

	for mirror in mirrors:
		if mirror.has_method("set_locked"):
			mirror.set_locked(true)

func _play_complete_sequence() -> void:
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

func _on_next_level_pressed() -> void:
	get_tree().paused = false

	if next_level_scene.is_empty():
		return

	get_tree().change_scene_to_file(next_level_scene)
