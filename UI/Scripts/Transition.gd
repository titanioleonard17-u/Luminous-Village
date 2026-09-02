extends CanvasLayer

var is_transitioning := false

func play(location: String) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	self.visible = true
	
	$Blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	
	$AnimationPlayer.play("Transition")
	await $AnimationPlayer.animation_finished
	
	get_tree().change_scene_to_file(location)
	await get_tree().create_timer(0.5).timeout
	
	$AnimationPlayer.play_backwards("Transition")
	await $AnimationPlayer.animation_finished
	
	$Blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	self.visible = false
	is_transitioning = false
