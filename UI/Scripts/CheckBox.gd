extends HBoxContainer
@export var text: String
@export var isChecked: bool

signal check_toggled(is_checked: bool)

func _ready() -> void:
	$Label.text = text
	$Button.isChecked = isChecked
	$Button.setCostume(int(isChecked))
	if isChecked:
		$Button.purpose = $Button.PurposeBtn.CHECKED
	else:
		$Button.purpose = $Button.PurposeBtn.UNCHECKED
	
	$Button.check_toggled.connect(_on_button_toggled)

func _on_button_toggled(is_checked: bool) -> void:
	isChecked = is_checked
	check_toggled.emit(is_checked)
