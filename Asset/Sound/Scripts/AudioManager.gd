extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var is_vibe_playing := false

enum AudioType {
	SFX,
	BGM,
	RANDOM_VIBE
}


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	bgm_player.finished.connect(_on_bgm_finished)


func playAudio(audio_name: String, type: AudioType) -> void:
	var path := ""

	match type:
		AudioType.SFX:
			path = find_sound(audio_name)

		AudioType.BGM:
			path = find_bgm(audio_name)
			is_vibe_playing = false

		AudioType.RANDOM_VIBE:
			path = get_random_vibe()
			is_vibe_playing = true

	if path == "":
		return

	var player := sfx_player if type == AudioType.SFX else bgm_player

	# Jangan restart kalau BGM yang sama masih sedang dimainkan
	if type != AudioType.SFX:
		var new_stream: AudioStream = load(path)

		if player.stream == new_stream and player.playing:
			return

		player.stream = new_stream
	else:
		player.stream = load(path)

	player.volume_db = get_sound_volume(path)
	player.play()


# =========================================================
# SFX
# =========================================================

func find_sound(sound_name: String) -> String:
	if sound_name == "ClickChecked" or sound_name == "ClickUnchecked":
		sound_name = "ClickDefault"

	var path := "res://Asset/Sound/SFX"
	var dir := DirAccess.open(path)

	if dir == null:
		push_error("Folder SFX tidak ditemukan: " + path)
		return ""

	var regex := RegEx.new()
	regex.compile("^(.+)_-?\\d+(?:\\.\\d+)?dB$")

	for file in dir.get_files():
		var base_name := file.get_basename()
		var result := regex.search(base_name)

		if result:
			var extracted_name := result.get_string(1)

			if extracted_name == sound_name:
				return path + "/" + file

	push_error("Sound tidak ditemukan: " + sound_name)
	return ""


# =========================================================
# BGM
# =========================================================

func find_bgm(bgm_name: String) -> String:
	var path := "res://Asset/Sound/BGM"
	var dir := DirAccess.open(path)

	if dir == null:
		push_error("Folder BGM tidak ditemukan: " + path)
		return ""

	var regex := RegEx.new()
	regex.compile("^(.+)_-?\\d+(?:\\.\\d+)?dB$")

	for file in dir.get_files():
		var base_name := file.get_basename()
		var result := regex.search(base_name)

		if result:
			var extracted_name := result.get_string(1)

			if extracted_name == bgm_name:
				return path + "/" + file

	push_error("BGM tidak ditemukan: " + bgm_name)
	return ""


func playRandomVibe() -> void:
	var path := get_random_vibe()

	if path == "":
		push_error("Tidak ada BGM Vibe!")
		return

	is_vibe_playing = true

	bgm_player.stream = load(path)
	bgm_player.volume_db = get_sound_volume(path)
	bgm_player.play()


func stopBGM() -> void:
	is_vibe_playing = false
	bgm_player.stop()


func isBGMPlaying() -> bool:
	return bgm_player.playing


func get_random_vibe() -> String:
	var path := "res://Asset/Sound/BGM"
	var dir := DirAccess.open(path)

	if dir == null:
		push_error("Folder BGM tidak ditemukan: " + path)
		return ""

	var vibe_songs: Array[String] = []

	var regex := RegEx.new()
	regex.compile("^.+Vibe_-?\\d+(?:\\.\\d+)?dB$")

	for file in dir.get_files():
		var base_name := file.get_basename()

		if regex.search(base_name):
			vibe_songs.append(path + "/" + file)

	if vibe_songs.is_empty():
		push_error("Tidak ada BGM Vibe!")
		return ""

	return vibe_songs.pick_random()


# =========================================================
# VOLUME
# =========================================================

func get_sound_volume(path: String) -> float:
	var file_name := path.get_file().get_basename()

	var regex := RegEx.new()
	regex.compile("_([+-]?\\d+(?:\\.\\d+)?)dB$")

	var result := regex.search(file_name)

	if result == null:
		push_error("Format volume audio tidak valid: " + file_name)
		return 0.0

	return float(result.get_string(1))


# =========================================================
# BGM FINISHED
# =========================================================

func _on_bgm_finished() -> void:
	if is_vibe_playing:
		playRandomVibe()
