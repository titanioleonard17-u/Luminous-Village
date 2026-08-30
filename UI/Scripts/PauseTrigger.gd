extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_pause_button_pressed() -> void:
	$PauseMenu.visible = true
