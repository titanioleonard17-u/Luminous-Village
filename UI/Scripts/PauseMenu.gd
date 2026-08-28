extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pause_button_pressed() -> void:
	$PauseMenuContainer.visible = true


func _on_resume_button_pressed() -> void:
	$PauseMenuContainer.visible = false


func _on_retry_button_pressed() -> void:
	pass # Replace with function body.
