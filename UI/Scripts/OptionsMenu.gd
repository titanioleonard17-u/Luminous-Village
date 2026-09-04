extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#AudioManager.playAudio("HomeScreen", AudioManager.AudioType.BGM)
	pass


func _on_back_button_pressed() -> void:
	visible = false
