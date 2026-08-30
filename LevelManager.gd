extends Node2D

@export var win_label_path: NodePath

var level_complete: bool = false
var win_label: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_complete = false
	if not win_label_path.is_empty():
		win_label = get_node(win_label_path)
		win_label.visible = false
		win_label.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if level_complete:
		return
	if _all_houses_lit():
		_trigger_win()

func _all_houses_lit() -> bool:
	var houses: Array = get_tree().get_nodes_in_group("house")
	if houses.is_empty():
		return false
	for house in houses:
		if not house.is_lit:
			return false
	return true

func _trigger_win() -> void:
	level_complete = true
	print("Semua rumah nyala! Level selesai.")

	# FREEZE LANGSUNG, sebelum animasi apapun
	get_tree().paused = true
	print("PAUSED STATUS: ", get_tree().paused)

	var houses: Array = get_tree().get_nodes_in_group("house")
	for house in houses:
		if house.has_method("celebrate"):
			house.celebrate()

	await get_tree().create_timer(0.5, true).timeout

	if win_label:
		win_label.visible = true
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		win_label.modulate.a = 0.0
		tween.tween_property(win_label, "modulate:a", 1.0, 0.6)
