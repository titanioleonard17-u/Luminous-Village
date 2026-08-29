extends CanvasLayer

func _ready() -> void:
	play()

func play():
	$AnimationPlayer.play("Transition")
	await get_tree().create_timer(1.5).timeout
	$AnimationPlayer.play_backwards("Transition")
