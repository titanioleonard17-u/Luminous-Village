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
			"button_size": Vector2(78, 78),
			"texture_size": Vector2(100, 100)
		},
		SizeBtn.MEDIUM: {
			"button_size": Vector2(135, 134),
			"texture_size": Vector2(172, 172)
		},
		SizeBtn.LARGE: {
			"button_size": Vector2(173, 170),
			"texture_size": Vector2(220, 220)
		}
	},

	TypeBtn.RECTANGLE: {
		SizeBtn.SMALL: {
			"button_size": Vector2(205, 84),
			"texture_size": Vector2(280, 280)
		},

		SizeBtn.MEDIUM: {
			"button_size": Vector2(295, 121),
			"texture_size": Vector2(400, 400)
		}
	}
}


func _ready() -> void:
	# Label
	$Label.text = text
	$Label.add_theme_font_size_override("font_size", fontSize)

	# Texture
	normalTexture = load(destinationImage)
	$TextureRect.texture = normalTexture
	$TextureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$TextureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Tunggu layout selesai sebelum mengatur ukuran
	call_deferred("_apply_size_config")


func _apply_size_config() -> void:
	var config = SIZE_CONFIG.get(typeButton, {}).get(sizeButton)

	if not config:
		print("Konfigurasi ukuran belum tersedia")
		return

	var button_size: Vector2 = config.button_size
	var texture_size: Vector2 = config.texture_size

	# =========================
	# BUTTON
	# =========================
	custom_minimum_size = button_size
	size = button_size

	# =========================
	# TEXTURE
	# =========================
	$TextureRect.size = texture_size

	# Center TextureRect terhadap TextureButton
	$TextureRect.position = (button_size - texture_size) / 2.0


func _on_mouse_entered() -> void:
	AudioManager.playAudio(
		"Hover",
		AudioManager.AudioType.SFX
	)

	if normalTexture:
		var path: String = normalTexture.resource_path

		$TextureRect.texture = load(
			path.get_basename() + " (Hover)." + path.get_extension()
		)


func _on_mouse_exited() -> void:
	if normalTexture:
		$TextureRect.texture = normalTexture


func _on_pressed() -> void:
	var purpose_name: String = PurposeBtn.keys()[purpose].to_lower().capitalize()

	print("Click" + purpose_name)

	AudioManager.playAudio(
		"Click" + purpose_name,
		AudioManager.AudioType.SFX
	)
