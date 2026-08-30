extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_resume_button_pressed() -> void:
	self.visible = false

func _on_retry_button_pressed() -> void:
	pass # Replace with function body.

func _on_exit_button_pressed() -> void:
	Transition.play("res://UI/Scenes/Homescreen.tscn")
