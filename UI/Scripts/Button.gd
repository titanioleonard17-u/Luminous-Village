extends TextureButton

enum TypeBtn {
	SQUARE,
	RECTANGLE
}
enum SizeBtn {
	SMALL,
	MEDIUM,
	LARGE
}
enum PurposeBtn {
	DEFAULT,
	OPEN,
	CLOSE
}

@export_file("*.png") var destinationImage: String
@export var typeButton: TypeBtn
@export var sizeButton: SizeBtn
@export var purpose: PurposeBtn = PurposeBtn.DEFAULT

@export_category("Advance")
@export var text: String
@export var fontSize: int = 80
@export_file("*.tscn") var triggerScenes: Array[String]

var normalTexture: Texture2D

const SIZE_CONFIG = {
	TypeBtn.SQUARE: {
		SizeBtn.SMALL: {
			"button_size": Vector2(97, 97),
			"texture_size": Vector2(124, 124),
			"texture_position": Vector2(-13, -12)
		},
		SizeBtn.LARGE: {
			"button_size": Vector2(173, 170),
			"texture_size": Vector2(220, 220),
			"texture_position": Vector2(-22.5, -23)
		},
	},

	TypeBtn.RECTANGLE: {
		SizeBtn.MEDIUM: {
			"button_size": Vector2(295, 121),
			"texture_size": Vector2(400, 400),
			"texture_position": Vector2(-152, -150)
		}
	}
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.text = text
	$Label.add_theme_font_size_override("font_size", fontSize)
	$TextureRect.texture = load(destinationImage)
	$TextureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$TextureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var config = SIZE_CONFIG.get(typeButton, {}).get(sizeButton)

	if config:
		custom_minimum_size = config.button_size
		#size = config.button_size
		$TextureRect.size = config.texture_size
		$TextureRect.position = config.texture_position
	else:
		print("Konfigurasi ukuran belum tersedia")

	normalTexture = $TextureRect.texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_mouse_entered() -> void:
	AudioManager.playSFX("Hover")
	var path = normalTexture.resource_path
	$TextureRect.texture = load(path.get_basename() + " (Hover)." + path.get_extension())


func _on_mouse_exited() -> void:
	$TextureRect.texture = load(normalTexture.resource_path)


func _on_pressed() -> void:
	print("Click" + PurposeBtn.keys()[purpose].to_lower().capitalize())
	AudioManager.playSFX("Click" + PurposeBtn.keys()[purpose].to_lower().capitalize())
		
