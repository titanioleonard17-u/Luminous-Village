extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.playAudio("HomeScreen", AudioManager.AudioType.BGM)
	
	for Row in $LevelBoxNode.get_children():
		print(Row.name)
		for LevelBox in Row.get_children():
			var index: int = int((LevelBox.name).trim_prefix("LevelBox")) + (int((Row.name).trim_prefix("Row")) - 1)*5
			var level_id: String = "Level" + str(index)
			#LevelBox.target_scene = "res://Colorless_files/Scenes/Levels/Level" + str(index) + ".tscn"
			
			#if SaveManager.is_level_completed(level_id) or SaveManager.is_current_level(level_id):
				#LevelBox.get_node("Lock").visible = false
			LevelBox.get_node("Label").text = str(index)
			
			#if SaveManager.is_level_completed(level_id):
				#var texture_rect: TextureRect = LevelBox.get_node("Border")
				#var atlas: AtlasTexture = texture_rect.texture.duplicate()
#
				#texture_rect.texture = atlas
				#atlas.region.position.x += 64
				#LevelBox.get_node("Label").add_theme_color_override("font_color", Color.WHITE)


func _on_button_pressed() -> void:
	Transition.play("res://UI/Scenes/HomeScreen.tscn")
