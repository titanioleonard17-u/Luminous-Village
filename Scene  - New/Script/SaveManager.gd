extends Node

const SAVE_PATH := "user://savegame.json"

var save_data := {
	"completed_levels": [],
	"current_level": "1",
}


func _ready() -> void:
	load_game()


# =========================
# SAVE
# =========================

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Gagal membuka savegame.json")
		return

	file.store_string(JSON.stringify(save_data))
	file.close()


# =========================
# LOAD
# =========================

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("Gagal membaca savegame.json")
		return

	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data is Dictionary:
		save_data.merge(data, true)


# =========================
# LEVEL
# =========================

func get_current_level() -> String:
	return save_data["current_level"]


func complete_level(level_name: String) -> void:
	# Tambahkan ke daftar level yang sudah selesai
	if not save_data["completed_levels"].has(level_name):
		save_data["completed_levels"].append(level_name)

	# Tentukan level berikutnya
	var next_level := int(level_name) + 1
	var current_level := int(save_data["current_level"])

	# Hanya update kalau progress-nya lebih jauh
	if next_level > current_level:
		save_data["current_level"] = "Level" + str(next_level)

	save_game()


func is_level_completed(level_name: String) -> bool:
	return save_data["completed_levels"].has(level_name)


# =========================
# RESET
# =========================

func reset_game() -> void:
	save_data = {
		"completed_levels": [],
		"current_level": "1",
	}

	save_game()
