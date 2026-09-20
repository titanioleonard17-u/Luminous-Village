extends Node

const SAVE_PATH := "user://saveguide.json"
const GAME_SAVE_PATH := "user://savegame.json"

var save_data := {}

var guide_data := {
	"step_1": [
		{
			"title": "Mirror",
			"description": [
				{"Function": "Cermin digunakan untuk memantulkan cahaya."},
				{"Reflection Side": "Ada sisi cermin yang dapat memantulkan, dan ada sisi yang tidak dapat memantulkan cahaya."},
				{"Mirror Rotation": "Cermin dapat diputar sebesar 360 derajat."},
				{"Mirror Spawner": "Cermin dapat di spawn dengan menekan angka 1."},
				{"Mirror Remover": "Cermin dapat dihapus dengan menekan tombol 0."},
				{"Prism Mirror": "Cermin Prisma dapat memecah 1 arah cahaya menjadi 2 arah. (Hanya mempunyai 1 sisi input)"},
				{"Mirror Distance": "Cermin tidak dapat di-spawn terlalu dekat dengan objek lain atau ketika kuota cermin telah habis."},
				{"Mirror Limit": "Ada batasan spawn cermin (kuota), setiap level dapat memiliki kuota yang berbeda-beda."},
				{"Reflection Limit": "Ada batas pantulan tertentu dalam tiap level, jika batas tercapai, maka cahaya tidak dapat terpantul. Jadi kami harap kamu bisa menciptakan jalur efisien."}
			]
		},
		{
			"title": "Button",
			"description": [
				{"Function": "Membuka pintu setelah terkena cahaya"},
				{"Reflection Side": "Hanya ada 1 sisi tombol yang dapat memantulkan cahaya."}
			]
		}
	]
}


func _ready() -> void:
	load_game()
	check_old_player()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data = {}
		save_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		print("Gagal membuka save game.")
		save_data = {}
		return

	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)

	if data is Dictionary:
		save_data = data
	else:
		print("Save game tidak valid.")
		save_data = {}


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()


func check_old_player() -> void:
	# Kalau step_1 sudah tersimpan, tidak perlu melakukan apa-apa.
	if save_data.has("step_1"):
		return

	# Cek apakah save game lama menunjukkan
	# bahwa player sudah menyelesaikan tutorial.
	if not FileAccess.file_exists(GAME_SAVE_PATH):
		return

	var file := FileAccess.open(GAME_SAVE_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var game_data = JSON.parse_string(content)

	if not game_data is Dictionary:
		return

	if game_data.get("tutorial_complete", false):
		unlock_guide("step_1")


func unlock_guide(step: String) -> void:
	if not guide_data.has(step):
		print("!!! MAAF, tidak ada key " + step + " !!!")
		return

	if not save_data.has(step):
		save_data[step] = []

	for guide in guide_data[step]:
		if guide not in save_data[step]:
			save_data[step].append(guide)

	save_game()


func get_guides(step = null):
	if step == null:
		return save_data

	if not save_data.has(step):
		return []

	return save_data[step]


func has_guide(step: String, guide: Dictionary) -> bool:
	return guide in get_guides(step)


func has_step(step: String) -> bool:
	return save_data.has(step)
