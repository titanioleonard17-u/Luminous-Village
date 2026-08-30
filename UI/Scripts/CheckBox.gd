extends HBoxContainer

@export var text: String
@export var isChecked: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.text = text
	$Button.isChecked = isChecked

	$Button.setCostume(int(isChecked))

	if isChecked:
		$Button.purpose = $Button.PurposeBtn.CHECKED
	else:
		$Button.purpose = $Button.PurposeBtn.UNCHECKED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
