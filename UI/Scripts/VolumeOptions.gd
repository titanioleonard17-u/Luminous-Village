extends VBoxContainer

var sfx_bus := AudioServer.get_bus_index("SFX")
var bgm_bus := AudioServer.get_bus_index("BGM")
var master_bus := AudioServer.get_bus_index("Master")

func _ready() -> void:
	if sfx_bus == -1:
		push_warning("Bus 'SFX' tidak ditemukan.")
	if bgm_bus == -1:
		push_warning("Bus 'BGM' tidak ditemukan.")
	
	$SFX/Button.check_toggled.connect(_on_sfx_toggled)
	$BGM/Button.check_toggled.connect(_on_bgm_toggled)
	$MasterVolume/MuteAllButton.check_toggled.connect(_on_mute_all_toggled)

func _on_sfx_toggled(is_checked: bool) -> void:
	if sfx_bus != -1:
		AudioServer.set_bus_mute(sfx_bus, !is_checked)

func _on_bgm_toggled(is_checked: bool) -> void:
	if bgm_bus != -1:
		AudioServer.set_bus_mute(bgm_bus, !is_checked)

func _on_mute_all_toggled(is_muted: bool) -> void:
	# Mute / unmute semua suara lewat Master bus
	AudioServer.set_bus_mute(master_bus, is_muted)
	
	# Ubah visual SFX dan BGM ke costume disabled
	$SFX/Button.setDisabledVisual(is_muted)
	$BGM/Button.setDisabledVisual(is_muted)
	
	# Slider Master Volume tetap tidak bisa digunakan saat Mute All aktif
	$MasterVolume/VolumeSlider.editable = not is_muted
