extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	on_light_hit()
	#pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_pressed():
	squish()

func on_light_hit():
	squish()
	
func squish():
	var tween = create_tween()
	
	tween.tween_property(self, "scale", Vector2(0.59, 0.41), 0.08)
	tween.tween_property(self, "scale", Vector2(0.46, 0.54), 0.06)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.08)
