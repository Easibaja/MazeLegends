#extends CharacterBody3D
#
#@export var walk_speed: float = 5.0
#@export var run_speed: float = 9.0
#
#const ANIM_IDLE    = "mixamo_com"
#const ANIM_WALK    = "Walking/mixamo_com"
#const ANIM_RUN     = "Running/mixamo_com"
#const ANIM_VICTORY = "Victory Idle/mixamo_com"
#
#@onready var anim_player: AnimationPlayer = $AnimationPlayer
#
#var current_anim := ""
#var _last_cell := Vector2i(-1, -1)
#
## top-down ish
#func _physics_process(delta):
	#print("player tick")
	#var input = Vector3.ZERO
	#input.x = Input.get_axis("ui_left", "ui_right")
	#input.z = Input.get_axis("ui_up", "ui_down")
#
	#var is_running = Input.is_action_pressed("run")
	#var speed = run_speed if is_running else walk_speed
#
	#if input.length() > 0.1:
		#input = input.normalized()
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
	#var cell = Vector2i(
		#int(global_position.x / HeatmapTracker.tile_size),
		#int(global_position.z / HeatmapTracker.tile_size)
	#)
	#if cell != _last_cell:
		#HeatmapTracker.record_position(global_position)
		#_last_cell = cell
#
#func _play_anim(anim_name: String) -> void:
	#if current_anim == anim_name:
		#return
	#if anim_player.has_animation(anim_name):
		#anim_player.play(anim_name)
		## Force loop
		#anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		#current_anim = anim_name
	#else:
		#push_warning("Animation not found: " + anim_name)
		#
