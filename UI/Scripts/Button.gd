extends TextureButton

enum TypeBtn {
	SQUARE,
	RECTANGLE
}

enum SizeBtn {
	EXTRA_SMALL,
	SMALL,
	MEDIUM,
	LARGE
}

enum PurposeBtn {
	DEFAULT,
	OPEN,
	CLOSE,
	CHECKED,
	UNCHECKED
}

signal check_toggled(is_checked: bool)

@export_category("Button")
@export var customes: Array[Texture2D]
@export var customes_disabled: Array[Texture2D]
@export var type_button: TypeBtn
@export var size_button: SizeBtn
@export var purpose: PurposeBtn = PurposeBtn.DEFAULT

@export_category("Advance")
@export var text: String
@export var font_size: int = 64

var current_costume: int = 0
var normal_texture: Texture2D
var isChecked: bool

const SIZE_CONFIG = {
	TypeBtn.SQUARE: {
		SizeBtn.EXTRA_SMALL: {
			"button_size": Vector2(55, 55),
			"texture_size": Vector2(70, 70)
		},
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
		SizeBtn.EXTRA_SMALL: {
			"button_size": Vector2(154, 63),
			"texture_size": Vector2(210, 210)
		},
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
	isChecked = purpose == PurposeBtn.CHECKED

	setupLabel()
	setupTexture()
	call_deferred("applySizeConfig")


func setupLabel() -> void:
	$Label.text = text
	$Label.add_theme_font_size_override("font_size", font_size)


func setupTexture() -> void:
	if customes.is_empty():
		push_warning("Customes belum diisi.")
		return

	normal_texture = customes[current_costume]

	$TextureRect.texture = normal_texture
	$TextureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$TextureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func applySizeConfig() -> void:
	var config = SIZE_CONFIG.get(type_button, {}).get(size_button)

	if not config:
		push_warning("Konfigurasi ukuran belum tersedia.")
		return

	var button_size: Vector2 = config.button_size
	var texture_size: Vector2 = config.texture_size

	custom_minimum_size = button_size
	size = button_size

	$TextureRect.size = texture_size
	$TextureRect.position = (button_size - texture_size) / 2.0


func _on_mouse_entered() -> void:
	# Disabled tidak boleh punya efek hover
	if disabled:
		return

	AudioManager.playAudio(
		"Hover",
		AudioManager.AudioType.SFX
	)

	applyHoverTexture()


func _on_mouse_exited() -> void:
	# Disabled tetap menggunakan texture disabled
	if disabled:
		return

	$TextureRect.texture = normal_texture


func applyHoverTexture() -> void:
	# Jangan apply hover kalau disabled
	if disabled:
		return

	if not normal_texture:
		return

	var path := normal_texture.resource_path
	var hover_path := path.get_basename() + " (Hover)." + path.get_extension()
	var hover_texture := load(hover_path)

	if hover_texture:
		$TextureRect.texture = hover_texture
	else:
		$TextureRect.texture = normal_texture


func _on_pressed() -> void:
	# Tambahan pengaman
	if disabled:
		return

	isChecked = !isChecked
	nextCostume()

	var purpose_name: String = PurposeBtn.keys()[purpose].to_lower().capitalize()

	AudioManager.playAudio(
		"Click" + purpose_name,
		AudioManager.AudioType.SFX
	)

	check_toggled.emit(isChecked)


func nextCostume() -> void:
	if customes.is_empty():
		return

	current_costume = (current_costume + 1) % customes.size()
	normal_texture = customes[current_costume]

	# Disabled tidak menggunakan hover
	if disabled:
		return

	if is_hovered():
		applyHoverTexture()
	else:
		$TextureRect.texture = normal_texture


func setCostume(index: int) -> void:
	if customes.is_empty():
		return

	if index < 0 or index >= customes.size():
		return

	current_costume = index
	normal_texture = customes[index]

	# Disabled tidak menggunakan hover
	if disabled:
		return

	if is_hovered():
		applyHoverTexture()
	else:
		$TextureRect.texture = normal_texture


func setDisabledVisual(disabled_state: bool) -> void:
	disabled = disabled_state

	var source := customes_disabled if disabled_state else customes

	if source.is_empty():
		return

	var index := int(isChecked)

	if index >= source.size():
		return

	normal_texture = source[index]

	# Saat disabled:
	# langsung gunakan texture disabled,
	# jangan pernah apply hover.
	if disabled:
		$TextureRect.texture = normal_texture
		return

	# Saat enabled kembali, cek apakah mouse sedang hover.
	if is_hovered():
		applyHoverTexture()
	else:
		$TextureRect.texture = normal_texture
