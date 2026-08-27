extends SubViewportContainer

@onready var sub_viewport: SubViewport = $Sub_Viewport

var dragging: bool = false
var last_drag_pos: Vector2 = Vector2.ZERO
var current_target = null

func _ready():
	get_viewport().size_changed.connect(_update_size)
	_update_size()

func _update_size():
	size = get_viewport().get_visible_rect().size

func _gui_input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
			last_drag_pos = event.position
			current_target = _find_glass_at(event.position)
		else:
			dragging = false
			current_target = null
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and dragging:
		var delta = event.position - last_drag_pos
		last_drag_pos = event.position
		if current_target:
			current_target.handle_drag(delta)

func _find_glass_at(screen_pos: Vector2):
	var cam = sub_viewport.get_camera_3d()
	if not cam:
		return null
	var from = cam.project_ray_origin(screen_pos)
	var dir = cam.project_ray_normal(screen_pos)
	var space_state = cam.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + dir * 1000)
	var result = space_state.intersect_ray(query)
	if result and result.collider.is_in_group("reflector"):
		return result.collider
	return null
