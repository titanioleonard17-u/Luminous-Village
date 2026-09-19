extends Control

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
@export var scroll_size := Vector2(1200, 700)

# =========================
# FONT SIZE
# =========================
@export var title_button_font_size := 28
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
	# TITLE / DESCRIPTION SIZE
	# =========================
	titleBoxContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	descriptionBoxContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	titleBoxContainer.size_flags_stretch_ratio = 1.0
	descriptionBoxContainer.size_flags_stretch_ratio = 2.0

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


func load_titles() -> void:
	for child in title_container.get_children():
		child.queue_free()

	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for step in guideBook:
		for guide in guideBook[step]:
			var title_button := Button.new()

			title_button.text = guide["title"]
			title_button.add_theme_font_override("font", guide_font)
			title_button.add_theme_font_size_override(
				"font_size",
				title_button_font_size
			)

			title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_button.custom_minimum_size.y = 50
			title_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

			title_button.pressed.connect(
				func(): show_guide(guide["title"])
			)

			title_container.add_child(title_button)


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
	title_label.add_theme_font_override("font", guide_font)
	title_label.add_theme_font_size_override(
		"font_size",
		title_font_size
	)

	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	container.add_child(title_label)

	# Jarak setelah title
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
			subtitle_label.add_theme_font_override("font", guide_font)
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
			description_label.add_theme_font_override("font", guide_font)
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
