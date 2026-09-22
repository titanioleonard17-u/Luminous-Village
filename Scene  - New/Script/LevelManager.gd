extends Node2D

@export_category("Animasi")
@export var slide_in_offset_y: float = 800.0
@export var sign_rise_offset: Vector2 = Vector2(0, -100)
@export var hold_duration: float = 1.2

@export_category("Win Delay")
@export var nightDelay: float = 0.5
@export var winDelay: float = 2.5
@export var transitionDuration: float = 0.5

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
var level_complete_path: NodePath


func _ready() -> void:
	if has_node("GuideStep"):
		var step := "step_" + str($GuideStep.currentStep)

		if not GuideManager.has_step(step):
			set_step_guide_status(true)
			$GuideStep.guideFinished.connect(_on_guide_finished)
		else:
			GuideManager.unlock_guide(step)
	
	AudioManager.playRandomVibe()

	level_complete_path = $LevelComplete.get_path()
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_complete = false
	
	$MirrorCounter.visible = true
	$NightModulate.visible = false
	$NightModeSwitch.visible = false
	$PauseTrigger.visible = true
	$LevelComplete.visible = false
	
	#_switch_to_night()

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
	if is_celebrating_win or level_complete:
		return

	is_celebrating_win = true
	celebration_id += 1

	var my_id: int = celebration_id

	var lasers: Array = get_tree().get_nodes_in_group("laser")
	var houses: Array = get_tree().get_nodes_in_group("house")

	# ==================================================
	# LOCK SEMUA MIRROR SEBELUM ADA ANIMASI / AWAIT
	# ==================================================
	_lock_mirrors()

	# Hilangkan laser
	for laser in lasers:
		laser.visible = false

	# Semua rumah mulai 3x squish
	for house in houses:
		if house.has_method("celebrate"):
			house.celebrate()

	# Tunggu sampai SEMUA rumah selesai celebrate
	while true:
		if my_id != celebration_id or not is_celebrating_win:
			return

		var all_finished := true

		for house in houses:
			if not house.is_lit:
				all_finished = false
				break

		if all_finished:
			break

		await get_tree().process_frame

	# ==================================================
	# MULAI NIGHT MODE
	# MIRROR SUDAH TIDAK BISA BERUBAH
	# ==================================================

	await get_tree().create_timer(nightDelay, true).timeout

	if my_id != celebration_id or not is_celebrating_win:
		return

	$NightModeSwitch.start_lights()

	await _switch_to_night()

	if my_id != celebration_id or not is_celebrating_win:
		return

	# Nyalakan semua lampu rumah
	for house in houses:
		if house.has_method("turn_on_lights"):
			house.turn_on_lights()

	await get_tree().create_timer(winDelay, true).timeout

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

	$LevelComplete.visible = true
	_play_complete_sequence()



func _show_night() -> void:
	$NightModulate.color = Color(1, 1, 1, 1)

	var tween := create_tween()

	tween.tween_property(
		$NightModulate,
		"color",
		Color(0.15, 0.15, 0.25, 1.0),
		transitionDuration
	)
	
	tween.parallel().tween_property(
		$DirectionalLight2D,
		"color",
		Color("517cfe"),
		transitionDuration
	)
	
	tween.parallel().tween_property(
		$DirectionalLight2D,
		"shadow_color",
		Color("1e0439"),
		transitionDuration
	)

	await tween.finished

#func _start_night_effects() -> void:
	#$Particle.restart()
	#$Particle.emitting = true
	#$LightController.start_lights()

func _switch_to_night() -> void:
	if is_switching_night:
		return

	is_switching_night = true

	$NightModulate.visible = true

	await _show_night()

	$PauseTrigger.enable_night_mode()
	$NightModeSwitch.visible = true


func _lock_mirrors() -> void:
	var mirrors: Array = get_tree().get_nodes_in_group("mirror")

	for mirror in mirrors:
		if mirror.has_method("set_locked"):
			mirror.set_locked(true)

	var cermin: Array = get_tree().get_nodes_in_group("cermin")

	for mirror in cermin:
		if mirror.has_method("set_locked"):
			mirror.set_locked(true)


func _play_complete_sequence() -> void:
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

func set_step_guide_status(value: bool) -> void:
	var objects = get_tree().get_nodes_in_group("mirror")
	var mechanismConfig = get_tree().get_nodes_in_group("mechanismUIConf")

	for object in objects:
		if object.has_method("set_step_guide_status"):
			object.set_step_guide_status(value)
	
	for mechanism in mechanismConfig:
		if mechanism.has_method("set_step_guide_status"):
			mechanism.set_step_guide_status(value)

func _on_guide_finished() -> void:
	GuideManager.unlock_guide("step_" + str($GuideStep.currentStep))
	set_step_guide_status(false)
