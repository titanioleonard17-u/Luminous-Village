extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TextButton/Label.text = name.trim_suffix('Button')
	$TextButton.pressed.connect(__OnButtonPressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func __OnButtonPressed():
	var action = name.trim_suffix("Button")
	match action.to_lower():
		"start":
			print("Start")
		"options":
			print("Options")
		"exit":
			print("Exit")
			get_tree().quit()
		_:
			print("Aksi '"+action+"' tidak terdaftar")
