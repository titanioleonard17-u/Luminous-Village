extends Control

func _ready() -> void:
	print(SaveManager.is_tutorial_completed())
	AudioManager.playAudio("HomeScreen", AudioManager.AudioType.BGM)
	for child in $ButtonNode.get_children():
		if child is BaseButton:
			child.pressed.connect(_on_button_pressed.bind(child))


func _on_button_pressed(button: BaseButton) -> void:
	match button.name.trim_suffix("Button").to_lower():
		"start":
			if not SaveManager.is_tutorial_completed():
				Transition.play("res://Scene  - New/Scene/Levels/TutorialLevel.tscn")
			else:
				Transition.play("res://UI/Scenes/LevelSelection.tscn")

		"options":
			$OptionsMenu.visible = true

		"exit":
			get_tree().quit()
