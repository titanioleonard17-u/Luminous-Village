extends CanvasLayer

var is_night_mode: bool = false
var is_step_guide_active: bool = false

@onready var pause_menu = $Container/PauseMenu
@onready var guide_book = $Container/GuideBook


func _ready() -> void:
	$"Container/PauseMenu".signal_close_pause_menu.connect(close_pause)
	$"Container/GuideBook".signal_close_guide_book.connect(_on_close_help_pressed)
	process_mode = Node.PROCESS_MODE_ALWAYS

	pause_menu.visible = false
	guide_book.visible = false


func _input(event: InputEvent) -> void:
	if is_night_mode:
		return

	if event.is_action_pressed("Escape"):
		if guide_book.visible:
			guide_book.visible = false
			get_tree().paused = false

			set_step_guide_status(false)

			AudioManager.playAudio(
				"ClickDefault",
				AudioManager.AudioType.SFX
			)

			get_viewport().set_input_as_handled()
			return

		if get_tree().paused:
			close_pause()
		else:
			_on_pause_button_pressed()

		get_viewport().set_input_as_handled()

	if event.is_action_pressed("HelpTrigger"):
		if not get_tree().paused:
			set_step_guide_status(true)
			_on_help_button_pressed()
			get_viewport().set_input_as_handled()


func open_pause() -> void:
	pause_menu.visible = true

	# Lock semua mekanisme
	set_step_guide_status(true)

	get_tree().paused = true

	AudioManager.playAudio(
		"ClickOpen",
		AudioManager.AudioType.SFX
	)


func close_pause() -> void:
	pause_menu.visible = false

	get_tree().paused = false

	# Unlock semua mekanisme
	set_step_guide_status(false)

	AudioManager.playAudio(
		"ClickClose",
		AudioManager.AudioType.SFX
	)


func open_help() -> void:
	if get_tree().paused:
		return

	guide_book.refresh_guide()

	guide_book.visible = not guide_book.visible
	get_tree().paused = true

	# Help terbuka → lock
	# Help tertutup → unlock
	set_step_guide_status(guide_book.visible)

	AudioManager.playAudio(
		"ClickDefault",
		AudioManager.AudioType.SFX
	)
	
func _on_close_help_pressed() -> void:
	if is_night_mode:
		return
	
	set_step_guide_status(false)

func _on_pause_button_pressed() -> void:
	if is_night_mode:
		return

	open_pause()


func _on_help_button_pressed() -> void:
	if is_night_mode:
		return

	open_help()


func enable_night_mode() -> void:
	is_night_mode = true

	pause_menu.visible = false
	guide_book.visible = false

	get_tree().paused = false

	# Night mode → lock mekanisme
	set_step_guide_status(true)


func set_step_guide_status(value: bool) -> void:
	is_step_guide_active = value

	var objects = get_tree().get_nodes_in_group("mirror")
	var mechanismConfig = get_tree().get_nodes_in_group("mechanismUIConf")

	for object in objects:
		if object.has_method("set_step_guide_status"):
			object.set_step_guide_status(value)

	for mechanism in mechanismConfig:
		if mechanism.has_method("set_step_guide_status") and mechanism != self:
			mechanism.set_step_guide_status(value)
