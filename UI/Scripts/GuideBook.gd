extends Control

@export var button_scene: PackedScene

# =========================
# TITLE BUTTON COSTUMES
# =========================
@export_category("Title Button")
@export var title_button_costumes: Array[Texture2D]
@export var title_button_costumes_disabled: Array[Texture2D]
@export var title_button_costume_index: int = 1

@onready var guideBook = GuideManager.get_guides()
@onready var titleBoxContainer = $MarginContainer/ContainerBox/TitleBoxMargin
@onready var descriptionBoxContainer = $MarginContainer/ContainerBox/DescriptionBoxMargin
@onready var title_container := $MarginContainer/ContainerBox/TitleBoxMargin/TitleBox/TitleMargin/ScrollContainer/VBoxContainer
@onready var scroll_container := $MarginContainer/ContainerBox/DescriptionBoxMargin/DescriptionBox/TextMargin/ScrollContainer
@onready var container := $MarginContainer/ContainerBox/DescriptionBoxMargin/DescriptionBox/TextMargin/ScrollContainer/VBoxContainer

var guide_font := SystemFont.new()

# =========================
# UI SIZE
# =========================
@export_category("UI")
@export var scroll_size := Vector2(1200, 700)

# =========================
# FONT SIZE
# =========================
@export var title_button_font_size := 48
@export var title_font_size := 48
@export var subtitle_font_size := 32
@export var description_font_size := 24

# =========================
# SPACING
# =========================
@export var title_spacing := 30.0
@export var section_spacing := 35.0


func _ready() -> void:
	# =========================
	# FONT
	# =========================
	guide_font.font_names = PackedStringArray(["Berlin Sans FB"])
	guide_font.subpixel_positioning = 0

	# =========================
	# TITLE / DESCRIPTION
	# =========================
	titleBoxContainer.size_flags_horizontal = Control.SIZE_FILL
	descriptionBoxContainer.size_flags_horizontal = Control.SIZE_FILL

	await get_tree().process_frame

	_resize_boxes()

	# =========================
	# TITLE LIST
	# =========================
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_titles()

	# =========================
	# SCROLL CONTAINER
	# =========================
	scroll_container.position = Vector2(50, 50)
	scroll_container.size = scroll_size

	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# =========================
	# SHOW DEFAULT GUIDE
	# =========================
	show_guide("Mirror")


# =========================
# RESIZE BOX
# =========================
func _resize_boxes() -> void:
	var parent := titleBoxContainer.get_parent()

	var total_width: float = parent.size.x

	if total_width <= 0:
		return

	# Simpan ukuran dan posisi asli dari scene
	var title_original_width: float = titleBoxContainer.size.x
	var description_original_width: float = descriptionBoxContainer.size.x

	var left_margin: float = titleBoxContainer.position.x

	var right_margin: float = total_width - (
		descriptionBoxContainer.position.x +
		description_original_width
	)

	var content_width: float = (
		total_width -
		left_margin -
		right_margin
	)

	if content_width <= 0:
		return

	var original_total_width: float = (
		title_original_width +
		description_original_width
	)

	if original_total_width <= 0:
		return

	# Ambil rasio dari desain asli scene
	var title_ratio: float = (
		title_original_width /
		original_total_width
	)

	var description_ratio: float = (
		description_original_width /
		original_total_width
	)

	# Terapkan rasio
	titleBoxContainer.size.x = (
		content_width *
		title_ratio
	)

	descriptionBoxContainer.size.x = (
		content_width *
		description_ratio
	)

	# Description tetap menempel di kanan
	descriptionBoxContainer.position.x = (
		total_width -
		right_margin -
		descriptionBoxContainer.size.x
	)


# =========================
# TITLE LIST
# =========================
func load_titles() -> void:
	for child in title_container.get_children():
		child.queue_free()

	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if button_scene == null:
		push_error("GuideBook: button_scene belum diisi di Inspector.")
		return

	if title_button_costumes.is_empty():
		print(
			"GuideBook: pakai customes bawaan scene button (index %d)"
			% title_button_costume_index
		)
	else:
		print(
			"GuideBook: pakai %d costume dari GuideBook (index %d)"
			% [
				title_button_costumes.size(),
				title_button_costume_index
			]
		)

	for step in guideBook:
		for guide in guideBook[step]:
			create_title_button(guide)


func create_title_button(guide: Dictionary) -> void:
	var title_button = button_scene.instantiate()

	title_button.type_button = title_button.TypeBtn.RECTANGLE
	title_button.size_button = title_button.SizeBtn.SMALL
	title_button.font_size = title_button_font_size

	# =========================
	# COSTUME
	# =========================
	if title_button_costumes.is_empty():
		title_button.setCostume(title_button_costume_index)
	else:
		title_button.setCostumes(
			title_button_costumes,
			title_button_costumes_disabled,
			title_button_costume_index
		)

	title_button.setText(guide["title"])
	title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_button.pressed.connect(
		show_guide.bind(guide["title"])
	)

	title_container.add_child(title_button)


# =========================
# GUIDE CONTENT
# =========================
func show_guide(title: String) -> void:
	for child in container.get_children():
		child.queue_free()

	for step in guideBook:
		for guide in guideBook[step]:
			if guide["title"] == title:
				_create_guide(guide)
				return


func _create_guide(guide: Dictionary) -> void:
	# =========================
	# TITLE
	# =========================
	var title_label := Label.new()

	title_label.text = guide["title"].to_upper()

	title_label.add_theme_font_override(
		"font",
		guide_font
	)

	title_label.add_theme_font_size_override(
		"font_size",
		title_font_size
	)

	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	container.add_child(title_label)

	# =========================
	# TITLE SPACING
	# =========================
	var title_space := Control.new()

	title_space.custom_minimum_size.y = title_spacing

	container.add_child(title_space)

	# =========================
	# DESCRIPTION
	# =========================
	for description in guide["description"]:
		for subtitle in description:
			# =========================
			# SUBTITLE
			# =========================
			var subtitle_label := Label.new()

			subtitle_label.text = subtitle

			subtitle_label.add_theme_font_override(
				"font",
				guide_font
			)

			subtitle_label.add_theme_font_size_override(
				"font_size",
				subtitle_font_size
			)

			subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			container.add_child(subtitle_label)

			# =========================
			# DESCRIPTION TEXT
			# =========================
			var description_label := Label.new()

			description_label.text = description[subtitle]

			description_label.add_theme_font_override(
				"font",
				guide_font
			)

			description_label.add_theme_font_size_override(
				"font_size",
				description_font_size
			)

			description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			container.add_child(description_label)

			# =========================
			# SECTION SPACING
			# =========================
			var space := Control.new()

			space.custom_minimum_size.y = section_spacing

			container.add_child(space)


# =========================
# BACK BUTTON
# =========================
func _on_back_button_pressed() -> void:
	visible = false
