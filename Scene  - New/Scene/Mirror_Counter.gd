extends CanvasLayer

@onready var label: Label = $Label

var _tween: Tween

func set_count(remaining: int, max_count: int) -> void:
	label.text = "%d / %d" % [remaining, max_count]

func play_error_effect() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	var original_pos: Vector2 = label.position
	label.modulate = Color.WHITE

	_tween = create_tween()
	# Flash merah
	_tween.tween_property(label, "modulate", Color.RED, 0.05)
	# Shake kiri-kanan
	_tween.tween_property(label, "position", original_pos + Vector2(-6, 0), 0.04)
	_tween.tween_property(label, "position", original_pos + Vector2(6, 0), 0.04)
	_tween.tween_property(label, "position", original_pos + Vector2(-4, 0), 0.04)
	_tween.tween_property(label, "position", original_pos + Vector2(4, 0), 0.04)
	_tween.tween_property(label, "position", original_pos, 0.04)
	# Balik ke putih
	_tween.parallel().tween_property(label, "modulate", Color.WHITE, 0.15)
