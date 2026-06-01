extends Camera3D

@export var distance: float = 30.0
@export var fov_value: float = 20.0
@export var follow_speed: float = 10.0
var target: Node3D = null

func _ready():
	projection = Camera3D.PROJECTION_PERSPECTIVE
	rotation_degrees = Vector3(-65, 0, 0)
	fov = fov_value
	near = 0.1
	far = 1000.0

func _physics_process(delta):
	if target:
		var forward = global_transform.basis.z.normalized()
		var desired_position = target.global_position + forward * distance
		position = position.lerp(desired_position, follow_speed * delta)
