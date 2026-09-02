extends Node

const SETTINGS_PATH := "user://settings.json"

var settings := {
	"master_volume": 1.0,
	"sfx_enabled": true,
	"bgm_enabled": true,
	"all_mute": false
}


func _ready() -> void:
	load_settings()
	apply_settings()


func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(settings))
		file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()

		if data is Dictionary:
			settings.merge(data, true)


func apply_settings() -> void:
	apply_master_volume()
	apply_sfx()
	apply_bgm()
	apply_all_mute()


func set_master_volume(value: float) -> void:
	settings["master_volume"] = clamp(value, 0.0, 1.0)
	apply_master_volume()
	save_settings()


func apply_master_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")

	if bus != -1:
		AudioServer.set_bus_volume_db(
			bus,
			linear_to_db(settings["master_volume"])
		)


func set_sfx_enabled(enabled: bool) -> void:
	settings["sfx_enabled"] = enabled
	apply_sfx()
	save_settings()


func apply_sfx() -> void:
	var bus := AudioServer.get_bus_index("SFX")

	if bus != -1:
		AudioServer.set_bus_mute(
			bus,
			not settings["sfx_enabled"]
		)


func set_bgm_enabled(enabled: bool) -> void:
	settings["bgm_enabled"] = enabled
	apply_bgm()
	save_settings()


func apply_bgm() -> void:
	var bus := AudioServer.get_bus_index("BGM")

	if bus != -1:
		AudioServer.set_bus_mute(
			bus,
			not settings["bgm_enabled"]
		)


func set_all_mute(muted: bool) -> void:
	settings["all_mute"] = muted
	apply_all_mute()
	save_settings()


func apply_all_mute() -> void:
	var bus := AudioServer.get_bus_index("Master")

	if bus != -1:
		AudioServer.set_bus_mute(
			bus,
			settings["all_mute"]
		)
