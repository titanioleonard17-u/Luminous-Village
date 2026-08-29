extends Control

func _ready() -> void:
	AudioManager.playAudio("Homescreen", AudioManager.AudioType.BGM)
	for child in $ButtonNode.get_children():
		if child is BaseButton:
			child.pressed.connect(_on_button_pressed.bind(child))


func _on_button_pressed(button: BaseButton) -> void:
	match button.name.trim_suffix("Button").to_lower():
		"start":
			get_tree().change_scene_to_file("res://UI/Scenes/LevelSelection.tscn")

		"options":
			print("Options")

		"exit":
			get_tree().quit()
