extends Control

var guideText = [
	"Sinari semua rumah dengan sinar yang ada.",
	"Button mempunyai cara kerja yang sama dengan cermin, hanya saja dia juga berfungsi untuk membuka gate.",
	"Ada sisi cermin yang dapat memantulkan, dan ada sisi yang tidak dapat memantulkan cahaya.",
	"Cermin dapat diputar sebesar 360 derajat.",
	"Prisma dapat memecah 1 arah cahaya menjadi 2 arah. (Hanya mempunya 1 sisi sisi input)",
	"Cermin dapat di spawn dengan menekan angka 1. (Cermin akan muncul tepat pada posisi mouse saat ini)",
	"Baik! Sudah waktunya untuk menyinari desa!"
]

@onready var label = $Container/MarginContainer/Label
@onready var page = $Container/Pages
var currentText = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ChangeText(currentText)

func ChangeText(id: int):
	label.text = guideText[currentText]
	page.text = str(currentText+1) + " / " + str(guideText.size())

func _on_back_button_pressed() -> void:
	currentText = clamp(currentText - 1, 0, guideText.size() - 1)
	ChangeText(currentText)


func _on_next_button_pressed() -> void:
	currentText = clamp(currentText + 1, 0, guideText.size() - 1)
	ChangeText(currentText)
