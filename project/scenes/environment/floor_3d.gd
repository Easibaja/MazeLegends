extends StaticBody3D

var mesh_instance: MeshInstance3D
var collision: CollisionShape3D
var grid_x: int = 0
var grid_z: int = 0

func setup(tile_size: float, tex: ImageTexture, tint: Color = Color.WHITE, gx: int = 0, gz: int = 0) -> void:
	grid_x = gx
	grid_z = gz
	mesh_instance = $MeshInstance3D
	collision = $CollisionShape3D
	var height := 0.1
	var mesh := mesh_instance.mesh as BoxMesh
	if mesh == null:
		mesh = BoxMesh.new()
		mesh_instance.mesh = mesh
	mesh.size = Vector3(tile_size * 0.5, height, tile_size * 0.5)
	var shape := collision.shape as BoxShape3D
	if shape == null:
		shape = BoxShape3D.new()
		collision.shape = shape
	shape.size = Vector3(tile_size * 0.5, height, tile_size * 0.5)
	mesh_instance.position.y = height / 2.0
	collision.position.y = height / 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = tint
	mat.roughness = 1.0
	mat.metallic = 0.0
	mesh_instance.material_override = mat

	var area = Area3D.new()
	var area_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(tile_size * 0.75, 1.0, tile_size * 0.75)
	area_shape.shape = box
	area.add_child(area_shape)
	area.position = Vector3(0, 0.5, 0)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		#print("[Floor] player entered cell (%d, %d)" % [grid_x, grid_z])
		HeatmapTracker.record_visit(grid_x, grid_z)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		HeatmapTracker.end_visit(grid_x, grid_z)
