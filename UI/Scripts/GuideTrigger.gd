extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("HelpTrigger"):
		$GuideMenu.visible = !$GuideMenu.visible
		AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)

func _on_help_button_pressed() -> void:
	$GuideMenu.visible = !$GuideMenu.visible
