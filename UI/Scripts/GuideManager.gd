extends Node

const SAVE_PATH := "user://saveguide.json"

var save_data := {}


func _ready() -> void:
	load_game()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)

	if data is Dictionary:
		save_data = data


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()


func unlock_guide(guide_data: Dictionary) -> void:
	for step in guide_data:
		if not save_data.has(step):
			save_data[step] = []

		for guide in guide_data[step]:
			if guide not in save_data[step]:
				save_data[step].append(guide)

	save_game()

func get_guides(step=null):
	if step == null:
		return save_data
		
	if not save_data.has(step):
		return []

	return save_data[step]


func has_guide(step: String, guide: Dictionary) -> bool:
	return guide in get_guides(step)
