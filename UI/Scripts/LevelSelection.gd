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

			# Hubungkan button ke level yang sesuai
			level_box.pressed.connect(
				_on_level_box_pressed.bind(index)
			)


func _on_level_box_pressed(index: int) -> void:
	var target_scene := "res://Scene  - New/Scene/Levels/Level%d.tscn" % index
	
	Transition.play(target_scene)


func _on_button_pressed() -> void:
	Transition.play("res://UI/Scenes/HomeScreen.tscn")
