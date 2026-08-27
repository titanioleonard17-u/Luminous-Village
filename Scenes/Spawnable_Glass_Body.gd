extends RigidBody3D

@export var rotation_sensitivity: float = 0.002
@export var torque_strength: float = 2.0

func _ready():
	gravity_scale = 0.0
	angular_damp = 6.0
	add_to_group("reflector")
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true

func handle_drag(delta: Vector2):
	var torque = Vector3(0, delta.x, 0) * torque_strength * rotation_sensitivity
	apply_torque_impulse(global_transform.basis * torque)
