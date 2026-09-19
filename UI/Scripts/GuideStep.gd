extends CanvasLayer

var guideTextStep1 = [
	"Sinari semua rumah dengan sinar yang ada.",
	"Button mempunyai cara kerja yang sama dengan cermin, hanya saja dia juga berfungsi untuk membuka gate.",
	"Ada sisi cermin yang dapat memantulkan, dan ada sisi yang tidak dapat memantulkan cahaya.",
	"Cermin dapat diputar sebesar 360 derajat.",
	"Cermin Prisma dapat memecah 1 arah cahaya menjadi 2 arah. (Hanya mempunya 1 sisi sisi input)",
	"Cermin dapat di spawn dengan menekan angka 1. (Cermin akan muncul tepat pada posisi mouse saat ini)",
	"Cermin dapat dihapus dengan menekan tombol 0. (Cermin dengan urutan terakhir yang terlebih dahulu dihapus)",
	"Cermin tidak dapat di spawn jika berjarak sangat dekat dengan objek lain, atau jika kuota cermin sudah habis.",
	"Ada batas pantulan teretentu dalam tiap level, jika batas tercapai, maka cahaya tidak dapat terpantul. Jadi kami harap kamu bisa menciptakan jalur efisien.",
	"Baik! Sudah waktunya untuk menyinari desa!"
]

var guideTextStep2 = [
	"Ini adalah panduan untuk tahap kedua.",
	"Contoh teks tahap kedua.",
	"Dan seterusnya..."
]

var guideBook = {
	"step_1": [
		{
			"title":"Mirror",
			"description":[
				{"Function":"Cermin digunakan untuk memantulkan cahaya."},
				{"Reflection Side":"Ada sisi cermin yang dapat memantulkan, dan ada sisi yang tidak dapat memantulkan cahaya."},
				{"Mirror Rotation":"Cermin dapat diputar sebesar 360 derajat."},
				{"Mirror Spawner":"Cermin dapat di spawn dengan menekan angka 1."},
				{"Mirror Remover":"Cermin dapat dihapus dengan menekan tombol 0."},
				{"Prism Mirror":"Cermin Prisma dapat memecah 1 arah cahaya menjadi 2 arah. (Hanya mempunya 1 sisi sisi input)"},
				{"Mirror Distance":"Cermin tidak dapat di-spawn terlalu dekat dengan objek lain atau ketika kuota cermin telah habis."},
				{"Mirror Limit":"Ada batasan spawn cermin (kuota), setiap level dapat memiliki kuota yang berbeda-beda."},
				{"Reflection Limit":"Ada batas pantulan teretentu dalam tiap level, jika batas tercapai, maka cahaya tidak dapat terpantul. Jadi kami harap kamu bisa menciptakan jalur efisien"}
			]
		},
		{
			"title":"Button",
			"description":[
				{"Function":"Membuka pintu setelah terkena cahaya"},
				{"Reflection Side":"Hanya ada 1 sisi tombol yang dapat memantulkan cahaya."}
			]
		}
	]
}

@onready var label = $ParentContainer/Container/MarginContainer/Label
@onready var page = $ParentContainer/Container/Pages

signal guideFinished

var currentText = 0
var currentStep = 1
var _tween: Tween

func _ready() -> void:
	show_guide(currentStep)

func show_guide(step: int) -> void:
	currentStep = step
	currentText = 0
	visible = true
	ChangeText(currentText)
	GuideManager.unlock_guide("step_1", guideBook)

func get_current_texts() -> Array:
	match currentStep:
		1:
			return guideTextStep1
		2:
			return guideTextStep2
		_:
			return guideTextStep1

func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("Back"):
			_on_back_button_pressed()
		elif event.is_action_pressed("Next"):
			_on_next_button_pressed()

func ChangeText(id: int) -> void:
	var texts = get_current_texts()

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
	_tween.tween_property(page, "modulate", Color.RED, 0.05)
	_tween.tween_property(page, "position", original_pos + Vector2(-6, 0), 0.04)
	_tween.tween_property(page, "position", original_pos + Vector2(6, 0), 0.04)
	_tween.tween_property(page, "position", original_pos + Vector2(-4, 0), 0.04)
	_tween.tween_property(page, "position", original_pos + Vector2(4, 0), 0.04)
	_tween.tween_property(page, "position", original_pos, 0.04)
	_tween.parallel().tween_property(page, "modulate", Color.WHITE, 0.15)
