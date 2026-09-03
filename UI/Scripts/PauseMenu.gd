extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	self.visible = false

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	Transition.play("res://UI/Scenes/LevelSelection.tscn")
