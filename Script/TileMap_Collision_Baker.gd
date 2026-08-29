extends Node3D
## Taruh script ini di Node3D kosong di dalam scene 3D kamu (misal: "Level_Colliders").
## Dia bakal baca TileMapLayer 2D yang dipakai designer sebagai "blueprint" layout,
## terus otomatis bikin StaticBody3D + collision beneran di posisi 3D yang sesuai.
##
## Designer TETEP kerja kayak biasa: gambar tile di TileMapLayer manapun (bisa pakai
## SEMUA warna/tile dari palette bebas) di scene yang khusus buat "solid" (collision).
## TileMapLayer-nya sendiri disembunyikan otomatis pas game run, karena cuma
## dipakai buat nentuin DI MANA collider harus muncul, bukan buat ditampilkan.

@export_group("Sumber TileMap")
@export var collision_layer_path: NodePath  ## TileMapLayer yang selnya = ada tembok/penghalang (misal isi Soild_Tile_Map)
@export var ground_layer_path: NodePath     ## TileMapLayer yang selnya = jalan/lantai (opsional, no collision)

@export_group("Ukuran Dunia 3D")
@export var world_tile_size: float = 2.0    ## Lebar 1 tile di dunia 3D (meter)
@export var wall_height: float = 3.0        ## Tinggi tembok/penghalang
@export var wall_thickness_margin: float = 0.0  ## Isi >0 kalau mau collider lebih kecil dikit dari tile (biar gak nempel2 aneh)

@export_group("Perilaku Laser")
@export var walls_reflect_laser: bool = false  ## true = laser mantul di tembok, false = laser berhenti di tembok

@export_group("Debug")
@export var show_debug_boxes: bool = false  ## Nyalain kalau mau lihat kotak collider pas testing


func _ready() -> void:
	_bake_colliders()


func _bake_colliders() -> void:
	if collision_layer_path.is_empty():
		push_warning("TileMap_Collision_Baker: collision_layer_path belum diisi di Inspector.")
		return

	var tilemap: TileMapLayer = get_node(collision_layer_path)
	if tilemap == null:
		push_warning("TileMap_Collision_Baker: node di collision_layer_path bukan TileMapLayer.")
		return

	# Semua cell yang ke-isi tile APAPUN (warna/jenis apapun) dianggap solid.
	var used_cells := tilemap.get_used_cells()
	for cell in used_cells:
		_spawn_wall_collider(tilemap, cell)

	# TileMapLayer cuma dipakai sebagai blueprint, jadi disembunyikan pas game jalan.
	# TileMapLayer sekarang tetap kelihatan sebagai visual di game.1


func _spawn_wall_collider(tilemap: TileMapLayer, cell: Vector2i) -> void:
	# Ambil posisi lokal cell (dalam koordinat TileMapLayer), lalu petakan ke bidang X-Z 3D.
	var local_pos: Vector2 = tilemap.map_to_local(cell)
	var world_x := (local_pos.x / tilemap.tile_set.tile_size.x) * world_tile_size
	var world_z := (local_pos.y / tilemap.tile_set.tile_size.y) * world_tile_size

	var body := StaticBody3D.new()
	body.name = "Wall_%d_%d" % [cell.x, cell.y]
	add_child(body)
	body.global_position = Vector3(world_x, wall_height / 2.0, world_z)

	var shape := BoxShape3D.new()
	var size := world_tile_size - wall_thickness_margin
	shape.size = Vector3(size, wall_height, size)

	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = shape
	body.add_child(collision_shape)

	if walls_reflect_laser:
		body.add_to_group("reflector")
	# Kalau false, gak perlu grup apa-apa — laser emitter kamu udah otomatis
	# berhenti di collider yang bukan anggota grup "reflector" atau "laser_switch".

	if show_debug_boxes:
		var mesh_instance := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = shape.size
		mesh_instance.mesh = box_mesh
		body.add_child(mesh_instance)
