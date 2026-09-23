extends Node

const SAVE_PATH := "user://saveguide.json"
const GAME_SAVE_PATH := "user://savegame.json"

var save_data := {}

var guide_data := {
	"step_1": [
		{
			"title": "House",
			"font_size": "auto",
			"description": [
				{"Function": "Obyektif utama untuk menyelesaikan permainan."}
			]
		},
		{
			"title": "Cahaya",
			"font_size": "auto",
			"description": [
				{"Function": "Cahaya utama yang digunakan untuk menghidupkan rumah-rumah yang ada di tiap level."},
				{"How to use": "Pantulkan cahaya ini ke semua rumah."}
			]
		},
		{
			"title": "Mirror",
			"font_size": "auto",
			"description": [
				{"Function": "Memantulkan cahaya."},
				{"Reflection Side": "Ada sisi cermin yang dapat memantulkan, dan ada sisi yang tidak dapat memantulkan cahaya."},
				{"Spawner": "Cermin dapat di spawn dengan menekan angka 1."},
				{"Remover": "Cermin dapat dihapus dengan menekan tombol 0."},
				{"Limit": "Ada batasan spawn cermin (kuota), setiap level dapat memiliki kuota yang berbeda-beda."},
				{"Distance": "Cermin tidak dapat di-spawn terlalu dekat dengan objek lain atau ketika kuota cermin telah habis."},
				{"Reflection Limit": "Ada batas pantulan tertentu dalam tiap level, jika batas tercapai, maka cahaya tidak dapat terpantul."}
			]
		},
		{
			"title": "Prism Mirror",
			"font_size": 32,
			"description": [
				{"Function": "Memecah 1 arah cahaya menjadi 2 arah."},
				{"Reflection Side": "Hanya ada 1 sisi input, sedangkan 2 sisi lainnya sebagai output."}
			]
		},
		{
			"title": "Button",
			"font_size": "auto",
			"description": [
				{"Function": "Membuka pintu setelah terkena cahaya."},
				{"Reflection Side": "Hanya ada 1 sisi tombol yang dapat memantulkan cahaya."}
			]
		},
		{
			"title": "Door",
			"font_size": "auto",
			"description": [
				{"Function": "Menghalangi cahaya agar tidak bisa lewat dengan leluasa."},
				{"How to open": "Sinarilah tombol yang ada sesuai dengan aturan untuk dapat membuka pintu."}
			]
		}
	],
	"step_2": [
		{
			"title": "Map Drag",
			"font_size": "auto",
			"description": [
				{"Function": "Menjelajahi peta lebih luas."},
				{"How to use": "Geser ke kiri-kanan atau atas-bawah untuk menggeser kamera. Adapun mouse-wheel untuk zoom-in dan zoom-out."}
			]
		}
	],
	"step_3": [
		{
			"title": "&& Button",
			"font_size": "auto",
			"description": [
				{"Function": "Tombol yang dirancang dengan mekanisme tertentu untuk membuka pintu."},
				{"How to use": "Sinari 2 buah '&& Button' secara bersamaan untuk membuka pintu."}
			]
		}
	],
	"step_4": [
		{
			"title": "Teleporter",
			"font_size": "auto",
			"description": [
				{"Function": "Memungkinkan cahya untuk berpindah tempat dari teleporter satu ke teleporter lainnya."}
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

	# Kalau file kosong
	if content.strip_edges().is_empty():
		print("Save game kosong, membuat save baru.")
		save_data = {}
		save_game()
		return

	var data = JSON.parse_string(content)

	if data is Dictionary:
		save_data = data
	else:
		print("Save game tidak valid, membuat save baru.")
		save_data = {}
		save_game()


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

	save_data[step] = guide_data[step].duplicate(true)
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
