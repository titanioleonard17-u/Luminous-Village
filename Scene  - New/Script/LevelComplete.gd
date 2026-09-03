extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	$Back_Button.process_mode = Node.PROCESS_MODE_ALWAYS
	$Back_Button.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_back_button_pressed() -> void:
	get_tree().paused = false
	Transition.play("res://UI/Scenes/LevelSelection.tscn")
