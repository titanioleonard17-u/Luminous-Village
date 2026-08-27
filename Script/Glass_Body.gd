extends RigidBody3D

@export var rotation_sensitivity: float = 0.002
@export var torque_strength: float = 2.0

func _ready():
	gravity_scale = 0.0
	angular_damp = 6.0
	add_to_group("reflector")
	
	# Kunci axis biar cuma bisa rotasi di Y, gak kepeleset ke X/Z
	axis_lock_angular_x = true
	axis_lock_angular_z = true

func handle_drag(delta: Vector2):
	# cuma pakai delta.x (gerakan horizontal), delta.y diabaikan
	var torque = Vector3(0, delta.x, 0) * torque_strength * rotation_sensitivity
	apply_torque_impulse(global_transform.basis * torque)
