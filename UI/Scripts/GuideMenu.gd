extends Control

var guideText = [
	"Sinari semua rumah dengan sinar yang ada.",
	"Button mempunyai cara kerja yang sama dengan cermin, hanya saja dia juga berfungsi untuk membuka gate.",
	"Ada sisi cermin yang dapat memantulkan, dan ada sisi yang tidak dapat memantulkan cahaya.",
	"Cermin dapat diputar sebesar 360 derajat.",
	"Prisma dapat memecah 1 arah cahaya menjadi 2 arah. (Hanya mempunya 1 sisi sisi input)",
	"Cermin dapat di spawn dengan menekan angka 1. (Cermin akan muncul tepat pada posisi mouse saat ini)",
	"Cermin tidak dapat di spawn jika berjarak sangat dekat dengan objek lain, atau jika kuota cermin sudah habis.",
	"Baik! Sudah waktunya untuk menyinari desa!"
]

@onready var label = $Container/MarginContainer/Label
@onready var page = $Container/Pages
var currentText = 0;
var _tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ChangeText(currentText)

func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("Back"):
			_on_back_button_pressed()
		elif event.is_action_pressed("Next"):
			_on_next_button_pressed()

func ChangeText(id: int):
	label.text = guideText[currentText]
	page.text = str(currentText+1) + " / " + str(guideText.size())

func _on_back_button_pressed() -> void:
	if currentText <= 0:
		play_error_effect()
		return

	currentText -= 1
	ChangeText(currentText)

func _on_next_button_pressed() -> void:
	if currentText >= guideText.size() - 1:
		currentText = 0
		visible = false
	else:
		currentText += 1
	ChangeText(currentText)

func play_error_effect() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	var original_pos: Vector2 = page.position
	page.modulate = Color.WHITE

	_tween = create_tween()
	# Flash merah
	_tween.tween_property(page, "modulate", Color.RED, 0.05)
	# Shake kiri-kanan
	_tween.tween_property(page, "position", original_pos + Vector2(-6, 0), 0.04)
	_tween.tween_property(page, "position", original_pos + Vector2(6, 0), 0.04)
	_tween.tween_property(page, "position", original_pos + Vector2(-4, 0), 0.04)
	_tween.tween_property(page, "position", original_pos + Vector2(4, 0), 0.04)
	_tween.tween_property(page, "position", original_pos, 0.04)
	# Balik ke putih
	_tween.parallel().tween_property(page, "modulate", Color.WHITE, 0.15)
