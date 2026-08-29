extends CanvasLayer

func play(location: String) -> void:
	self.visible = true
	
	# Tutup layar
	$AnimationPlayer.play("Transition")
	await $AnimationPlayer.animation_finished
	
	# Ganti scene saat layar sudah tertutup
	get_tree().change_scene_to_file(location)
	await get_tree().create_timer(0.5).timeout
	
	# Buka layar
	$AnimationPlayer.play_backwards("Transition")
	await $AnimationPlayer.animation_finished
	
	self.visible = false
