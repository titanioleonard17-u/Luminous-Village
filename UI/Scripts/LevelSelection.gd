extends Control


func _ready() -> void:
	AudioManager.playAudio("HomeScreen", AudioManager.AudioType.BGM)

	for row in $LevelBoxNode.get_children():
		var row_index := int(row.name.trim_prefix("Row")) - 1

		for level_box in row.get_children():
			var box_index := int(level_box.name.trim_prefix("LevelBox"))

			# Hitung index level
			var index := box_index + row_index * 5
			var level_id := "Level" + str(index)

			# Tampilkan nomor level
			level_box.get_node("Label").text = str(index)

			# Cek apakah level sudah terbuka
			var unlocked := _is_level_unlocked(index)

			# Atur status button
			level_box.disabled = not unlocked
			if unlocked:
				var defaultTexture: Texture2D = load("res://Asset/Art/LevelSelection/Button - Level.png")
				level_box.customes[0] = defaultTexture
				level_box.setCostume(0)
				print(level_box.customes)

			# Hubungkan button
			level_box.pressed.connect(
				_on_level_box_pressed.bind(index)
			)


func _is_level_unlocked(index: int) -> bool:
	# Level 1 selalu terbuka
	if index == 1:
		return true

	# Level berikutnya terbuka jika level sebelumnya selesai
	var previous_level := "Level" + str(index - 1)

	return SaveManager.is_level_completed(previous_level)


func _on_level_box_pressed(index: int) -> void:
	var level_id := "Level" + str(index)
	var target_scene := "res://Scene  - New/Scene/Levels/Level%d.tscn" % index

	Transition.play(target_scene)


func _on_button_pressed() -> void:
	Transition.play("res://UI/Scenes/HomeScreen.tscn")
