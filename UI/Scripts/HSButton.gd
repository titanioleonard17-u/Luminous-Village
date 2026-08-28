extends TextureButton

@export_file("*.png") var destinationImage: String

var action: String
var normalTexture: Texture2D


func _ready() -> void:
	action = name.trim_suffix("Button")

	if destinationImage.is_empty():
		$Label.text = action
	else:
		$TextureRect.texture = load(destinationImage)
		normalTexture = $TextureRect.texture
		$Label.visible = false


func __OnButtonPressed() -> void:
	match action.to_lower():
		"start":
			print("Start")
			get_tree().change_scene_to_file("res://UI/Scenes/LevelSelection.tscn")

		"options":
			print("Options")

		"exit":
			print("Exit")
			get_tree().quit()

		_:
			print("Aksi '" + action + "' tidak terdaftar")


func _on_mouse_entered() -> void:
	if normalTexture == null:
		return

	var path := normalTexture.resource_path
	var hover_path := path.get_basename() + " (Hover)." + path.get_extension()

	if ResourceLoader.exists(hover_path):
		$TextureRect.texture = load(hover_path)


func _on_mouse_exited() -> void:
	if normalTexture != null:
		$TextureRect.texture = normalTexture
