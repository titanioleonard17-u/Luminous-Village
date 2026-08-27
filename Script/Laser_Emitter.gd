extends Node3D

@export var max_bounces: int = 8
@export var laser_length: float = 50.0
@export var laser_color: Color = Color(1, 0, 0)
@export var laser_width: float = 0.03

var mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh
var material: StandardMaterial3D

func _ready():
	immediate_mesh = ImmediateMesh.new()
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = laser_color
	material.emission_enabled = true
	material.emission = laser_color
	material.vertex_color_use_as_albedo = false

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _physics_process(_delta):
	cast_laser()

func cast_laser():
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin
	var direction = -global_transform.basis.z.normalized()

	immediate_mesh.surface_add_vertex(to_local(origin))

	for i in range(max_bounces):
		var query = PhysicsRayQueryParameters3D.create(origin, origin + direction * laser_length)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query)

		if result.is_empty():
			immediate_mesh.surface_add_vertex(to_local(origin + direction * laser_length))
			break

		var hit_point = result.position
		immediate_mesh.surface_add_vertex(to_local(hit_point))

		var collider = result.collider
		if collider.is_in_group("reflector"):
			var normal = result.normal
			direction = direction.bounce(normal)
			origin = hit_point + direction * 0.01
			print("Laser mantul kena reflector di: ", hit_point)
		else:
			print("Laser berhenti, kena: ", collider.name)
			break

	immediate_mesh.surface_end()
