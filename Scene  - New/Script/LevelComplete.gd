extends Control


func _ready() -> void:
	# Tetap bisa menerima input walaupun game sedang di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	# Level di-pause setelah menang, jadi wajib dibuka dulu
	get_tree().paused = false
	
	# Jalankan transition ke Level Selection
	Transition.play("res://UI/Scenes/LevelSelection.tscn")
