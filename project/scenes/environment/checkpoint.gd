extends Area3D
signal collected
var sphere_mesh: MeshInstance3D
var ring_mesh: MeshInstance3D
var ring_mesh2: MeshInstance3D
var spotlight: SpotLight3D
var is_collected := false
var pulse_time := 0.0

func _ready():
	sphere_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.175
	sphere.height = 0.35
	sphere_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.0)
	mat.emission_energy_multiplier = 4.0
	sphere_mesh.material_override = mat
	add_child(sphere_mesh)

	ring_mesh = MeshInstance3D.new()
	var ring = TorusMesh.new()
	ring.inner_radius = 0.2
	ring.outer_radius = 0.275
	ring_mesh.mesh = ring
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.0, 0.8, 1.0, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.0, 0.0, 1.0)
	ring_mat.emission_energy_multiplier = 4.0
	ring_mesh.material_override = ring_mat
	ring_mesh.rotation_degrees.x = 90.0
	add_child(ring_mesh)

	ring_mesh2 = MeshInstance3D.new()
	var ring2 = TorusMesh.new()
	ring2.inner_radius = 0.2
	ring2.outer_radius = 0.275
	ring_mesh2.mesh = ring2
	var ring_mat2 = StandardMaterial3D.new()
	ring_mat2.albedo_color = Color(0.0, 0.8, 1.0)
	ring_mat2.emission_enabled = true
	ring_mat2.emission = Color(0.0, 0.0, 1.0)
	ring_mat2.emission_energy_multiplier = 4.0
	ring_mesh2.material_override = ring_mat2
	ring_mesh2.rotation_degrees.x = 45.0
	add_child(ring_mesh2)

	spotlight = SpotLight3D.new()
	spotlight.position = Vector3(0, 4.0, 0)
	spotlight.rotation_degrees.x = -90.0
	spotlight.light_color = Color(1.0, 0.95, 0.6)
	spotlight.light_energy = 30.0
	spotlight.spot_range = 6.0
	spotlight.spot_angle = 10.0
	spotlight.spot_angle_attenuation = 5.0
	spotlight.shadow_enabled = false
	add_child(spotlight)

	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.55
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)

func _process(delta):
	if is_collected:
		return
	sphere_mesh.rotation.y += delta * 2.0
	ring_mesh.rotation.z += delta * 3.0
	ring_mesh2.rotation.z -= delta * 2.0
	pulse_time += delta * 3.0
	var pulse = 1.0 + sin(pulse_time) * 0.5
	(sphere_mesh.material_override as StandardMaterial3D).emission_energy_multiplier = 4.0 * pulse
	spotlight.light_energy = 30.0 + sin(pulse_time) * 20.0

func _on_body_entered(body):
	if body is CharacterBody3D and not is_collected:
		is_collected = true
		emit_signal("collected")
		queue_free()
