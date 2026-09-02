extends VBoxContainer

var sfx_bus := AudioServer.get_bus_index("SFX")
var bgm_bus := AudioServer.get_bus_index("BGM")
var master_bus := AudioServer.get_bus_index("Master")


func _ready() -> void:
	if sfx_bus == -1:
		push_warning("Bus 'SFX' tidak ditemukan.")

	if bgm_bus == -1:
		push_warning("Bus 'BGM' tidak ditemukan.")

	if master_bus == -1:
		push_warning("Bus 'Master' tidak ditemukan.")

	$SFX/Button.check_toggled.connect(_on_sfx_toggled)
	$BGM/Button.check_toggled.connect(_on_bgm_toggled)
	$MasterVolume/MuteAllButton.check_toggled.connect(_on_mute_all_toggled)
	$MasterVolume/VolumeSlider.value_changed.connect(_on_master_volume_changed)

	_load_settings_to_ui()


func _load_settings_to_ui() -> void:
	# SFX
	$SFX.isChecked = SettingsManager.settings["sfx_enabled"]
	$SFX/Button.isChecked = SettingsManager.settings["sfx_enabled"]
	$SFX/Button.setCostume(
		int(SettingsManager.settings["sfx_enabled"])
	)

	# BGM
	$BGM.isChecked = SettingsManager.settings["bgm_enabled"]
	$BGM/Button.isChecked = SettingsManager.settings["bgm_enabled"]
	$BGM/Button.setCostume(
		int(SettingsManager.settings["bgm_enabled"])
	)

	# Mute All
	var is_muted: bool = SettingsManager.settings["all_mute"]

	$MasterVolume/MuteAllButton.isChecked = is_muted
	$MasterVolume/MuteAllButton.setCostume(int(is_muted))

	if is_muted:
		$MasterVolume/MuteAllButton.purpose = $MasterVolume/MuteAllButton.PurposeBtn.CHECKED
	else:
		$MasterVolume/MuteAllButton.purpose = $MasterVolume/MuteAllButton.PurposeBtn.UNCHECKED

	# Master Volume
	$MasterVolume/VolumeSlider.value = (
		SettingsManager.settings["master_volume"] * 100.0
	)

	# Disabled visual
	$SFX/Button.setDisabledVisual(is_muted)
	$BGM/Button.setDisabledVisual(is_muted)
	$MasterVolume/VolumeSlider.editable = not is_muted


func _on_sfx_toggled(is_checked: bool) -> void:
	SettingsManager.set_sfx_enabled(is_checked)


func _on_bgm_toggled(is_checked: bool) -> void:
	SettingsManager.set_bgm_enabled(is_checked)


func _on_mute_all_toggled(is_muted: bool) -> void:
	SettingsManager.set_all_mute(is_muted)

	$SFX/Button.setDisabledVisual(is_muted)
	$BGM/Button.setDisabledVisual(is_muted)
	$MasterVolume/VolumeSlider.editable = not is_muted


func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value / 100.0)
