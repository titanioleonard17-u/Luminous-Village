extends TextureButton

@export_file(".png") var destination_image: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if destination_image.is_empty():
		$Label.text = name.trim_suffix('Button')
	else:
		$TextureRect.texture = load(destination_image)
		$Label.visible = false
	
	print(name.trim_suffix("Button").to_lower())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func __OnButtonPressed():
	var action = name.trim_suffix("Button")
	match action.to_lower():
		"start":
			print("Start")
			get_tree().change_scene_to_file('res://UI/Scenes/LevelSelection.tscn')
		"options":
			print("Options")
		"exit":
			print("Exit")
			get_tree().quit()
		_:
			print("Aksi '"+action+"' tidak terdaftar")
