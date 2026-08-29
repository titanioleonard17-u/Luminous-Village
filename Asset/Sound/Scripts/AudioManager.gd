extends Node

#var SFX = {
	#"hoverSFX": preload("res://Asset/Sound/SFX/Hover.wav"),
	#"clickDefaultSFX": preload("res://Asset/Sound/SFX/ClickButton.wav"),
	#"clickOpenSFX": preload("res://Asset/Sound/SFX/ClickOpen.wav"),
	#"clickCloseSFX": preload("res://Asset/Sound/SFX/ClickClose.wav")
#}
var regex := RegEx.new()

var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func playSFX(sfx: String) -> void:
	var path := find_sound(sfx)

	if path == "":
		push_error("SFX tidak ditemukan: " + sfx)
		return

	audio_player.stream = load(path)
	audio_player.volume_db = get_sound_volume(path)
	audio_player.play()

func find_sound(sound_name: String) -> String:
	var path := "res://Asset/Sound/SFX"
	var dir := DirAccess.open(path)

	if dir == null:
		push_error("Folder SFX tidak ditemukan: " + path)
		return ""

	var regex := RegEx.new()
	regex.compile("^([^_]+)_-?\\d+dB$")

	for file in dir.get_files():
		var base_name := file.get_basename()
		var result := regex.search(base_name)

		if result:
			var extracted_name := result.get_string(1)

			if extracted_name == sound_name:
				return path + "/" + file

	push_error("Sound tidak ditemukan: " + sound_name)
	return ""

func get_sound_volume(path: String) -> float:
	var file_name := path.get_file().get_basename()

	var regex := RegEx.new()
	regex.compile("_([+-]?\\d+)dB$")

	var result := regex.search(file_name)

	if result == null:
		push_error("Format volume SFX tidak valid: " + file_name)
		return 0.0

	return float(result.get_string(1))
