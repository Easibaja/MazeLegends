extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var run_speed:  float = 9.0

@onready var may = $Idle

var has_won:    bool = false
var is_running: bool = false

const COLLISION_COOLDOWN: float = 0.4
var _collision_timer: float = 0.0

var _was_moving: bool = false

const STUCK_THRESHOLD: float = 3.0
const STUCK_COOLDOWN:  float = 5.0
var _stuck_timer:    float    = 0.0
var _stuck_cooldown: float    = 0.0
var _last_grid_cell: Vector2i = Vector2i(-1, -1)

const IDLE_MIN_DURATION: float = 2.0
var _idle_timer:    float = 0.0
var _is_idle:       bool  = false

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta):
	if has_won:
		return

	_collision_timer = max(_collision_timer - delta, 0.0)
	_stuck_cooldown  = max(_stuck_cooldown  - delta, 0.0)

	if Input.is_action_just_pressed("run"):
		is_running = !is_running
		EventTracker.record(
			"button_press",
			"run_on" if is_running else "run_off",
			global_position
		)

	var input     = Vector3.ZERO
	input.x       = Input.get_axis("ui_left", "ui_right")
	input.z       = Input.get_axis("ui_up",   "ui_down")
	var speed     = run_speed if is_running else walk_speed
	var is_moving = input.length() > 0.1

	if is_moving and not _was_moving:
		EventTracker.record("movement_start", "run" if is_running else "walk", global_position)
	elif not is_moving and _was_moving:
		EventTracker.record("movement_stop", "run" if is_running else "walk", global_position)
	_was_moving = is_moving

	if is_moving:
		input = input.normalized()
		velocity.x = input.x * speed
		velocity.z = input.z * speed
		look_at(global_position - Vector3(input.x, 0, input.z), Vector3.UP)
		may._play_anim(may.ANIM_RUN if is_running else may.ANIM_WALK)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		may._play_anim(may.ANIM_IDLE)

	velocity.y -= 9.8 * delta
	move_and_slide()

	if is_on_wall() and _collision_timer == 0.0 and is_moving:
		_collision_timer = COLLISION_COOLDOWN
		EventTracker.record("wall_collision", _get_collision_direction(), global_position)

	_update_stuck(delta, is_moving)
	_update_idle(delta, is_moving)

func _update_stuck(delta: float, is_moving: bool) -> void:
	if not is_moving:
		_stuck_timer = 0.0
		return

	var tile = _get_tile_size()
	var cell = Vector2i(
		int(global_position.x / tile),
		int(global_position.z / tile)
	)

	if cell != _last_grid_cell:
		_last_grid_cell = cell
		_stuck_timer    = 0.0
		return

	_stuck_timer += delta

	if _stuck_timer >= STUCK_THRESHOLD and _stuck_cooldown == 0.0:
		EventTracker.record(
			"player_stuck",
			"stuck",
			global_position,
			_stuck_timer
		)
		_stuck_timer    = 0.0
		_stuck_cooldown = STUCK_COOLDOWN

func _update_idle(delta: float, is_moving: bool) -> void:
	if not is_moving:
		_idle_timer += delta
		_is_idle     = true
	else:
		if _is_idle and _idle_timer >= IDLE_MIN_DURATION:
			EventTracker.record(
				"player_idle",
				"idle",
				global_position,
				_idle_timer
			)
		_idle_timer = 0.0
		_is_idle    = false

func _get_tile_size() -> float:
	var parent = get_parent()
	if parent and "tile_size" in parent:
		return parent.tile_size
	return 2.0

func _get_collision_direction() -> String:
	for i in get_slide_collision_count():
		var col  = get_slide_collision(i)
		var n    = col.get_normal()
		var flat = Vector2(n.x, n.z)
		if flat.length() < 0.1:
			continue
		var angle = rad_to_deg(atan2(flat.x, flat.y))
		if   angle > -45  and angle <=  45:  return "north"
		elif angle >  45  and angle <= 135:  return "east"
		elif angle > 135  or  angle <= -135: return "south"
		else:                                return "west"
	return "unknown"

func trigger_victory():
	has_won  = true
	velocity = Vector3.ZERO
	may.trigger_victory()
