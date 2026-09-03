extends Control
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$PauseMenu.visible = false
func _on_pause_button_pressed() -> void:
	$PauseMenu.visible = true
	get_tree().paused = true
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("PauseTrigger"):
		if get_tree().paused:
			AudioManager.playAudio("ClickClose", AudioManager.AudioType.SFX)
			$PauseMenu.visible = false
			get_tree().paused = false
		else:
			AudioManager.playAudio("ClickOpen", AudioManager.AudioType.SFX)
			$PauseMenu.visible = true
			get_tree().paused = true
