extends Node

var SFX = {
	"hoverSFX": preload("res://Asset/Sound/SFX/Hover.wav"),
	"clickDefaultSFX": preload("res://Asset/Sound/SFX/ClickButton.wav"),
	"clickOpenSFX": preload("res://Asset/Sound/SFX/ClickOpen.wav"),
	"clickCloseSFX": preload("res://Asset/Sound/SFX/ClickClose.wav")
}

var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func playSFX(sfx: String):
	audio_player.stream = SFX[sfx + "SFX"]
	audio_player.play()

#func play_hover() -> void:
	#audio_player.stream = hoverSFX
	#audio_player.play()
#
#
#func play_click() -> void:
	#audio_player.stream = clickButtonSFX
	#audio_player.play()
