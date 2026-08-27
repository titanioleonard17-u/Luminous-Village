extends Node3D

@export var max_bounces: int = 8
@export var laser_length: float = 150.0
@export var laser_color: Color = Color(1.0, 0.95, 0.4)
@export var laser_width: float = 0.05  # sekarang beneran dipakai, dalam meter

var material: StandardMaterial3D
var segment_meshes: Array = []

func _ready():
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = laser_color
	material.emission_enabled = true
	material.emission = laser_color
	material.emission_energy_multiplier = 4.0

func _physics_process(_delta):
	cast_laser()

func cast_laser():
	# hapus segment lama
	for seg in segment_meshes:
		seg.queue_free()
	segment_meshes.clear()

	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin
	var direction = -global_transform.basis.z.normalized()

	for i in range(max_bounces):
		var query = PhysicsRayQueryParameters3D.create(origin, origin + direction * laser_length)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query)

		var end_point: Vector3
		if result.is_empty():
			end_point = origin + direction * laser_length
			_draw_segment(origin, end_point)
			break
		else:
			end_point = result.position
			_draw_segment(origin, end_point)

			var collider = result.collider
			if collider.is_in_group("reflector"):
				var normal = result.normal
				direction = direction.bounce(normal)
				origin = end_point + direction * 0.1
			else:
				break

func _draw_segment(from: Vector3, to: Vector3):
	var seg_length = from.distance_to(to)
	if seg_length < 0.001:
		return

	var box = BoxMesh.new()
	box.size = Vector3(laser_width, laser_width, seg_length)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	add_child(mesh_instance)
	segment_meshes.append(mesh_instance)

	var mid_point = (from + to) / 2.0
	mesh_instance.global_position = mid_point
	mesh_instance.look_at(to, Vector3.UP)
