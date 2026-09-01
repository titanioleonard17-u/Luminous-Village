extends HSlider

var master_bus := AudioServer.get_bus_index("Master")

func _ready():
	value = 100
	value_changed.connect(_on_volume_changed)

func _on_volume_changed(volume: float):
	AudioServer.set_bus_volume_db(
		master_bus,
		linear_to_db(volume / 100.0)
	)
	$Label.text = str(volume / 100.0)
