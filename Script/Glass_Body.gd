extends RigidBody3D
@export var rotation_sensitivity: float = 0.002
@export var torque_strength: float = 2.0
@export var door_path: NodePath

var is_hit_this_frame: bool = false

func _ready():
	gravity_scale = 0.0
	angular_damp = 6.0
	add_to_group("reflector")
	add_to_group("laser_switch")
	axis_lock_angular_x = true
	axis_lock_angular_z = true

func handle_drag(delta: Vector2):
	var torque = Vector3(0, delta.x, 0) * torque_strength * rotation_sensitivity
	apply_torque_impulse(global_transform.basis * torque)

func activate():
	is_hit_this_frame = true
	var door = get_node(door_path)
	door.set_door_state(true)

func _physics_process(_delta):
	if not is_hit_this_frame:
		var door = get_node(door_path)
		door.set_door_state(false)
	is_hit_this_frame = false  # reset untuk frame berikutnya
