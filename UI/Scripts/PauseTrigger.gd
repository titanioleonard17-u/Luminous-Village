extends CanvasLayer

var is_night_mode: bool = false
var is_step_guide_active: bool = false

@onready var pause_menu = $Container/PauseMenu
@onready var guide_menu = $Container/GuideBook


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	pause_menu.visible = false
	guide_menu.visible = false


func _input(event: InputEvent) -> void:
	if is_night_mode or is_step_guide_active:
		return

	if event.is_action_pressed("Escape"):
		if guide_menu.visible:
			guide_menu.visible = false
			AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)
			return

		if get_tree().paused:
			close_pause()
		else:
			open_pause()

		get_viewport().set_input_as_handled()


	if event.is_action_pressed("HelpTrigger"):
		if not get_tree().paused:
			guide_menu.visible = not guide_menu.visible
			AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)
			get_viewport().set_input_as_handled()


func open_pause() -> void:
	pause_menu.visible = true
	get_tree().paused = true
	AudioManager.playAudio("ClickOpen", AudioManager.AudioType.SFX)


func close_pause() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	AudioManager.playAudio("ClickClose", AudioManager.AudioType.SFX)


func _on_pause_button_pressed() -> void:
	if is_night_mode:
		return

	open_pause()


func _on_help_button_pressed() -> void:
	if is_night_mode:
		return

	if get_tree().paused:
		return

	guide_menu.visible = not guide_menu.visible
	AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)


func enable_night_mode() -> void:
	is_night_mode = true

	pause_menu.visible = false
	guide_menu.visible = false

	get_tree().paused = false

func set_step_guide_status(value: bool) -> void:
	is_step_guide_active = value
