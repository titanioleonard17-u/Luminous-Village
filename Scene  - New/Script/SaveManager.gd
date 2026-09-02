extends Node

const SAVE_PATH := "user://savegame.json"

var save_data := {
	"completed_levels": [],
	"current_level": "",
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
# RESET
# =========================

func reset_game() -> void:
	save_data = {
		"version": 1,
		"completed_levels": [],
		"current_level": "",
		"game_progress": {}
	}

	save_game()
