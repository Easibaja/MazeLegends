extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var run_speed: float = 9.0

const ANIM_IDLE = "Twilight_Idle/Take 001"
const ANIM_WALK = "Twilight_Walk/Take 001"
const ANIM_RUN  = "Twilight_Run/Take 001"

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var current_anim := ""

# Isometric
#func _physics_process(delta):
	#var input = Vector3.ZERO
	#input.x = Input.get_axis("ui_left", "ui_right")
	#input.z = Input.get_axis("ui_up", "ui_down")
#
	#var is_running = Input.is_action_pressed("run")
	#var speed = run_speed if is_running else walk_speed
#
	#if input.length() > 0.1:
		#input = input.normalized()
		#input = input.rotated(Vector3.UP, deg_to_rad(45))
#
		#velocity.x = input.x * speed
		#velocity.z = input.z * speed
#
		#look_at(global_position - Vector3(input.x, 0, input.z), Vector3.UP)
#
		#_play_anim(ANIM_RUN if is_running else ANIM_WALK)
	#else:
		#velocity.x = move_toward(velocity.x, 0, speed)
		#velocity.z = move_toward(velocity.z, 0, speed)
		#_play_anim(ANIM_IDLE)
#
	#velocity.y -= 9.8 * delta
	#move_and_slide()

# top-down ish
func _physics_process(delta):
	var input = Vector3.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.z = Input.get_axis("ui_up", "ui_down")

	var is_running = Input.is_action_pressed("run")
	var speed = run_speed if is_running else walk_speed

	if input.length() > 0.1:
		input = input.normalized()

		velocity.x = input.x * speed
		velocity.z = input.z * speed

		look_at(global_position - Vector3(input.x, 0, input.z), Vector3.UP)

		_play_anim(ANIM_RUN if is_running else ANIM_WALK)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		_play_anim(ANIM_IDLE)

	velocity.y -= 9.8 * delta
	move_and_slide()

func _play_anim(anim_name: String) -> void:
	if current_anim == anim_name:
		return
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		# Force loop
		anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		current_anim = anim_name
	else:
		push_warning("Animation not found: " + anim_name)
		
