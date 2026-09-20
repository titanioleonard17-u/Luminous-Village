extends Control


# =========================================================
# BUTTON SCENE
# =========================================================

@export var button_scene: PackedScene


# =========================================================
# TITLE BUTTON COSTUMES
# =========================================================

@export_category("Title Button")

@export var title_button_costumes: Array[Texture2D]
@export var title_button_costumes_disabled: Array[Texture2D]
@export var title_button_costume_index: int = 1


# =========================================================
# GUIDE DATA
# =========================================================

var guideBook = {}


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var title_list: VBoxContainer = $MarginContainer/ContainerBox/TitleList/ScrollContainer/VBoxContainer

@onready var title_scroll_container: ScrollContainer = $MarginContainer/ContainerBox/TitleList/ScrollContainer

@onready var description_scroll: ScrollContainer = $MarginContainer/ContainerBox/Description/ScrollContainer

@onready var description_container: VBoxContainer = $MarginContainer/ContainerBox/Description/ScrollContainer/VBoxContainer


# =========================================================
# FONT
# =========================================================

var guide_font := SystemFont.new()


# =========================================================
# FONT SIZE
# =========================================================

@export_category("Font Size")

@export var list_font_size: int = 48
@export var title_font_size: int = 48
@export var subtitle_font_size: int = 32
@export var text_font_size: int = 24


# =========================================================
# LIST COLOR
# =========================================================

@export_category("List Color")

@export var list_color := Color("#000000")


# =========================================================
# DESCRIPTION COLOR
# =========================================================

@export_category("Description Color")

@export var description_color := Color.BLACK


# =========================================================
# LIST SPACING
# =========================================================

@export_category("List Spacing")

@export var list_spacing: float = 20.0


# =========================================================
# DESCRIPTION SPACING
# =========================================================

@export_category("Description Spacing")

@export var title_to_subtitle_spacing: float = 8
@export var subtitle_to_text_spacing: float = 0
@export var text_to_subtitle_spacing: float = 24


# =========================================================
# SELECTED TITLE
# =========================================================

var selected_title := ""


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	guide_font.font_names = PackedStringArray([
		"Berlin Sans FB"
	])

	guide_font.subpixel_positioning = 0


	# =====================================================
	# TITLE SCROLL
	# =====================================================

	title_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	title_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	title_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	title_list.add_theme_constant_override(
		"separation",
		int(list_spacing)
	)


	# =====================================================
	# DESCRIPTION SCROLL
	# =====================================================

	description_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	description_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	description_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	description_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


	# =====================================================
	# LOAD GUIDE
	# =====================================================

	refresh_guide()


# =========================================================
# REFRESH GUIDE
# =========================================================

func refresh_guide() -> void:

	guideBook = GuideManager.get_guides()

	load_titles()

	selected_title = ""

	for child in description_container.get_children():
		child.queue_free()


	if guideBook.is_empty():
		return


	var first_step = guideBook.values()[0]

	if first_step.is_empty():
		return


	show_guide(first_step[0]["title"])


# =========================================================
# TITLE LIST
# =========================================================

func load_titles() -> void:

	for child in title_list.get_children():
		child.queue_free()


	if button_scene == null:
		push_error("GuideBook: button_scene belum diisi di Inspector.")
		return


	for step in guideBook:

		for guide in guideBook[step]:

			create_title_button(guide)


# =========================================================
# CREATE TITLE BUTTON
# =========================================================

func create_title_button(guide: Dictionary) -> void:

	var title_button = button_scene.instantiate()


	# =====================================================
	# BUTTON SETTINGS
	# =====================================================

	title_button.type_button = title_button.TypeBtn.RECTANGLE
	title_button.size_button = title_button.SizeBtn.SMALL

	title_button.font_size = list_font_size
	
	title_button.get_node("Label").add_theme_color_override(
		"font_color",
		list_color
	)


	# =====================================================
	# BUTTON COSTUME
	# =====================================================

	if title_button_costumes.is_empty():

		title_button.setCostume(
			title_button_costume_index
		)

	else:

		title_button.setCostumes(
			title_button_costumes,
			title_button_costumes_disabled,
			title_button_costume_index
		)


	# =====================================================
	# BUTTON TEXT
	# =====================================================

	title_button.setText(
		guide["title"]
	)

	title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# =====================================================
	# PRESSED
	# =====================================================

	title_button.pressed.connect(
		func():
			selected_title = guide["title"]
			show_guide(guide["title"])
	)


	title_list.add_child(title_button)


# =========================================================
# SHOW GUIDE
# =========================================================

func show_guide(title: String) -> void:

	selected_title = title


	for child in description_container.get_children():
		child.queue_free()


	for step in guideBook:

		for guide in guideBook[step]:

			if guide["title"] == title:

				_create_guide(guide)

				await get_tree().process_frame

				description_scroll.scroll_vertical = 0

				return


# =========================================================
# CREATE GUIDE CONTENT
# =========================================================

func _create_guide(guide: Dictionary) -> void:

	# =====================================================
	# TITLE
	# =====================================================

	var title_label := Label.new()

	title_label.text = guide["title"].to_upper()

	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title_label.add_theme_font_override(
		"font",
		guide_font
	)

	title_label.add_theme_font_size_override(
		"font_size",
		title_font_size
	)

	title_label.add_theme_color_override(
		"font_color",
		description_color
	)

	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	description_container.add_child(title_label)


	# =====================================================
	# TITLE → SUBTITLE SPACING
	# =====================================================

	var title_space := Control.new()

	title_space.custom_minimum_size.y = title_to_subtitle_spacing

	description_container.add_child(title_space)


	# =====================================================
	# DESCRIPTION
	# =====================================================

	var first_section := true

	for description in guide["description"]:

		for subtitle in description:

			# -------------------------------------------------
			# SPACING ANTAR SECTION
			# -------------------------------------------------

			if not first_section:

				var section_space := Control.new()

				section_space.custom_minimum_size.y = text_to_subtitle_spacing

				description_container.add_child(section_space)

			first_section = false


			# -------------------------------------------------
			# SUBTITLE
			# -------------------------------------------------

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

			subtitle_label.add_theme_color_override(
				"font_color",
				description_color
			)

			subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			description_container.add_child(subtitle_label)


			# -------------------------------------------------
			# SUBTITLE → TEXT SPACING
			# -------------------------------------------------

			var subtitle_space := Control.new()

			subtitle_space.custom_minimum_size.y = subtitle_to_text_spacing

			description_container.add_child(subtitle_space)


			# -------------------------------------------------
			# DESCRIPTION TEXT
			# -------------------------------------------------

			var description_label := Label.new()

			description_label.text = description[subtitle]

			description_label.add_theme_font_override(
				"font",
				guide_font
			)

			description_label.add_theme_font_size_override(
				"font_size",
				text_font_size
			)

			description_label.add_theme_color_override(
				"font_color",
				description_color
			)

			description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			description_container.add_child(description_label)


# =========================================================
# BACK BUTTON
# =========================================================

func _on_back_button_pressed() -> void:

	visible = false
