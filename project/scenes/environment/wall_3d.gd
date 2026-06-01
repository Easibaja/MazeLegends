extends StaticBody3D

var mesh_instance: MeshInstance3D
var collision: CollisionShape3D

func setup(tile_size: float, wall_height: float, tex: ImageTexture, tint: Color = Color.WHITE):
	mesh_instance = $MeshInstance3D
	collision = $CollisionShape3D
	var mesh := mesh_instance.mesh as BoxMesh
	if mesh == null:
		mesh = BoxMesh.new()
		mesh_instance.mesh = mesh
	mesh.size = Vector3(tile_size * 0.5, wall_height, tile_size * 0.5)
	var shape := collision.shape as BoxShape3D
	if shape == null:
		shape = BoxShape3D.new()
		collision.shape = shape
	shape.size = Vector3(tile_size * 0.5, wall_height, tile_size * 0.5)
	mesh_instance.position.y = wall_height / 2.0
	collision.position.y = wall_height / 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = tint
	mat.roughness = 0.9
	mat.metallic = 0.0
	mesh_instance.material_override = mat
