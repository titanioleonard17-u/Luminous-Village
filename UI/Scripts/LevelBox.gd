extends TextureButton

var normalTexture: Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normalTexture = $TextureRect.texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	AudioManager.playAudio("Hover", AudioManager.AudioType.SFX)
	var path = normalTexture.resource_path
	$TextureRect.texture = load(path.get_basename() + " (Hover)." + path.get_extension())


func _on_mouse_exited() -> void:
	$TextureRect.texture = load(normalTexture.resource_path)

func _on_pressed() -> void:
	AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)
