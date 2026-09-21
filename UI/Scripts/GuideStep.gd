extends CanvasLayer

var guideTexts = [
	[
		{"text": "Sinari semua rumah dengan sinar yang ada.", "action": ""},
		{"text": "Button mempunyai cara kerja yang sama dengan cermin, hanya saja dia juga berfungsi untuk membuka gate.", "action": ""},
		{"text": "Ada sisi cermin yang dapat memantulkan, dan ada sisi yang tidak dapat memantulkan cahaya.", "action": ""},
		{"text": "Cermin dapat diputar sebesar 360 derajat.", "action": ""},
		{"text": "Cermin Prisma dapat memecah 1 arah cahaya menjadi 2 arah. (Hanya mempunyai 1 sisi input)", "action": ""},
		{"text": "Cermin dapat di-spawn dengan menekan angka 1. (Cermin akan muncul tepat pada posisi mouse saat ini)", "action": ""},
		{"text": "Cermin dapat dihapus dengan menekan tombol 0. (Cermin dengan urutan terakhir yang terlebih dahulu dihapus)", "action": ""},
		{"text": "Cermin tidak dapat di-spawn jika berjarak sangat dekat dengan objek lain, atau jika kuota cermin sudah habis.", "action": ""},
		{"text": "Ada batas pantulan tertentu dalam tiap level, jika batas tercapai, maka cahaya tidak dapat terpantul. Jadi kami harap kamu bisa menciptakan jalur efisien.", "action": ""},
		{"text": "Baik! Sudah waktunya untuk menyinari desa!", "action": ""}
	],
	[
		{"text": "Hmm, sepertinya peta ini semakin membesar.", "action": ""},
		{"text": "Mulai sekarang kamu bisa menggerakan kamera.", "action": ""},
		{"text": "Cobalah menggesernya ke atas-bawah ataupun kiri-kanan.", "action": ""},
		{"text": "Baiklah, selamat bersenang-senang!", "action": ""}
	],
	[
		{"text": "Lihat, muncul varian button baru.", "action": ""},
		{"text": "Kamu harus menyinari 2 button untuk dapat membuka pintu.", "action": ""},
		{"text": "Baiklah! Selamat mencoba.", "action": ""}
	],
	[
		{"text": "Tidak mungkin cahaya bisa menembus tebing begitu saja.", "action": ""},
		{"text": "Kami baru saja menemukan teknologi canggih.", "action": ""},
		{"text": "Cobalah!", "action": ""}
	]
]

@onready var label = $ParentContainer/Container/MarginContainer/Label
@onready var page = $ParentContainer/Container/Pages

signal guideFinished

var currentText = 0
@export var currentStep = 1
var _tween: Tween


func _ready() -> void:
	visible = false

	if not GuideManager.has_step("step_" + str(currentStep)):
		show_guide(currentStep)


func show_guide(step: int) -> void:
	currentStep = step
	currentText = 0
	visible = true

	ChangeText(currentText)


func get_current_texts() -> Array:
	var index = currentStep - 1

	if index < 0 or index >= guideTexts.size():
		return []

	return guideTexts[index]


func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("Back"):
			_on_back_button_pressed()
		elif event.is_action_pressed("Next"):
			_on_next_button_pressed()


func ChangeText(id: int) -> void:
	var texts = get_current_texts()

	if texts.is_empty():
		return

	label.text = texts[currentText]
	page.text = str(currentText + 1) + " / " + str(texts.size())


func _on_back_button_pressed() -> void:
	var texts = get_current_texts()

	if currentText <= 0:
		play_error_effect()
		return

	AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)

	currentText -= 1
	ChangeText(currentText)


func _on_next_button_pressed() -> void:
	var texts = get_current_texts()

	if currentText >= texts.size() - 1:
		AudioManager.playAudio("ClickClose", AudioManager.AudioType.SFX)

		currentText = 0
		visible = false

		guideFinished.emit()
	else:
		AudioManager.playAudio("ClickDefault", AudioManager.AudioType.SFX)

		currentText += 1
		ChangeText(currentText)


func play_error_effect() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	var original_pos: Vector2 = page.position
	page.modulate = Color.WHITE

	_tween = create_tween()

	_tween.tween_property(
		page,
		"modulate",
		Color.RED,
		0.05
	)

	_tween.tween_property(
		page,
		"position",
		original_pos + Vector2(-6, 0),
		0.04
	)

	_tween.tween_property(
		page,
		"position",
		original_pos + Vector2(6, 0),
		0.04
	)

	_tween.tween_property(
		page,
		"position",
		original_pos + Vector2(-4, 0),
		0.04
	)

	_tween.tween_property(
		page,
		"position",
		original_pos + Vector2(4, 0),
		0.04
	)

	_tween.tween_property(
		page,
		"position",
		original_pos,
		0.04
	)

	_tween.parallel().tween_property(
		page,
		"modulate",
		Color.WHITE,
		0.15
	)
