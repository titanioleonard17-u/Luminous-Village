extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$PauseMenu.visible = false
	$GuideMenu.visible = false
	#Level1/PauseContainer/PauseTriger/GuideMenu
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		if not $GuideMenu.visible:
			if get_tree().paused:
				AudioManager.playAudio("ClickClose", AudioManager.AudioType.SFX)
				$PauseMenu.visible = false
				get_tree().paused = false
			else:
				AudioManager.playAudio("ClickOpen", AudioManager.AudioType.SFX)
				$PauseMenu.visible = true
				get_tree().paused = true
		else:
			$GuideMenu.visible = !$GuideMenu.visible
			AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)
	elif event.is_action_pressed("HelpTrigger") and not $PauseMenu.visible:
		$GuideMenu.visible = !$GuideMenu.visible
		AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)

func _on_pause_button_pressed() -> void:
	$PauseMenu.visible = true
	get_tree().paused = true
	
func _on_help_button_pressed() -> void:
	$GuideMenu.visible = !$GuideMenu.visible
