extends Node3D

@export var wall_scene: PackedScene
@export var floor_scene: PackedScene
@export var checkpoint_scene: PackedScene
@export var player_scene: PackedScene
@export var hud_scene: PackedScene

@export var tile_size: float = 2.0
@export var wall_height: float = 1.5
@export var alt_pattern_chance: float = 0.15

var level_ended := false

const SUPABASE_URL = Env.SUPABASE_URL
const SUPABASE_API_KEY = Env.SUPABASE_KEY

const QUADRANT_DIVISIONS: int = 3

const QUADRANT_COLORS: Array = [
	Color(0.812, 0.0,   0.228, 1.0),
	Color(0.0,   0.58,  0.262, 1.0),
	Color(0.0,   0.419, 0.775, 1.0),
	Color(0.737, 0.717, 0.0,   1.0),
	Color(0.6,   0.0,   0.8,   1.0),
	Color(0.9,   0.45,  0.0,   1.0),
	Color(0.0,   0.7,   0.75,  1.0),
	Color(0.85,  0.2,   0.5,   1.0),
	Color(0.3,   0.3,   0.3,   1.0),
	Color(0.0,   0.35,  0.35,  1.0),
	Color(0.75,  0.1,   0.1,   1.0),
	Color(0.1,   0.1,   0.6,   1.0),
	Color(0.55,  0.27,  0.07,  1.0),
	Color(0.0,   0.55,  0.45,  1.0),
	Color(0.8,   0.4,   0.0,   1.0),
	Color(0.45,  0.0,   0.45,  1.0),
]

var maze_container: Node3D

var college_id := ""
var algorithm  := ""

var current_level := 0

var levels = [
	{ "size": 11, "seed": 200402910, "checkpoints": 1, "time_limit": 120 },
	{ "size": 21, "seed": 200402910, "checkpoints": 3, "time_limit": 180 },
	{ "size": 31, "seed": 200402910, "checkpoints": 5, "time_limit": 600 }
]

var hud = null
var maze: Array = []

var pending_size:        int = 25
var pending_seed:        int = 0
var pending_checkpoints: int = 0

var total_checkpoints:     int = 0
var collected_checkpoints: int = 0

var wall_textures:  Array = []
var floor_textures: Array = []

var dominant_wall:  int = 0
var dominant_floor: int = 0

var exit_dialog: ConfirmationDialog
var level_timer_seconds := 0.0

var _cp_search_start: float = 0.0

var remaining_time := 0.0
var shared_time_bank := 0.0

func _ready():
	_setup_lighting()

	maze_container = Node3D.new()
	add_child(maze_container)

	exit_dialog = ConfirmationDialog.new()
	exit_dialog.dialog_text = "Return to main menu?"
	exit_dialog.confirmed.connect(_on_exit_confirmed)
	exit_dialog.canceled.connect(_on_exit_canceled)
	exit_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	add_child(exit_dialog)

	set_process(true)

	load_level(current_level)

func load_level(index: int):
	if index >= levels.size():
		_return_to_menu()
		return

	var data = levels[index]

	pending_size        = data["size"]
	pending_seed        = data["seed"]
	pending_checkpoints = data["checkpoints"]

	if pending_seed == 0:
		pending_seed = randi()

	level_timer_seconds = 0.0
	level_ended = false

	# Pull carried time from session singleton
	remaining_time = data["time_limit"] + GameSession.carried_time

	# Reset after consuming
	GameSession.carried_time = 0.0

	EventTracker.set_session(
		college_id,
		pending_seed,
		index + 1,
		tile_size
	)

	EventTracker.record("level_start", algorithm)

	_cp_search_start = 0.0

	generate_and_draw(
		pending_size,
		pending_seed,
		pending_checkpoints,
		algorithm
	)

func generate_and_draw(size: int, maze_seed: int, checkpoints_num: int, type: String):
	match type:
		"backtracking":
			maze = MazeGenerator.generate_recursive_backtracking(
				size, maze_seed, checkpoints_num
			)
		"sidewinder":
			maze = MazeGenerator.generate_sidewinder(
				size, maze_seed, checkpoints_num
			)
		"division":
			maze = MazeGenerator.generate_division(
				size, maze_seed, checkpoints_num
			)
		_:
			push_error("Unknown maze type: " + type)
			return

	total_checkpoints     = 0
	collected_checkpoints = 0

	HeatmapTracker.initialize(
		maze[0].size(),
		maze.size(),
		maze
	)

	draw_maze()

func draw_maze():
	wall_textures = [
		TextureGenerator.wall_large_brick(),
		TextureGenerator.wall_small_brick(),
		TextureGenerator.wall_rough_stone()
	]

	floor_textures = [
		TextureGenerator.floor_cobble(),
		TextureGenerator.floor_large_cobble(),
		TextureGenerator.floor_flagstone()
	]

	if hud == null:
		hud = hud_scene.instantiate()
		add_child(hud)

	dominant_wall  = randi() % wall_textures.size()
	dominant_floor = randi() % floor_textures.size()

	for z in range(maze.size()):
		for x in range(maze[z].size()):

			var cell = maze[z][x]
			var pos  = Vector3(x * tile_size, 0, z * tile_size)
			var tint = _get_quadrant_tint(x, z)

			var wall_tint = tint.lerp(
				Color(tint.r, tint.g, tint.b) * 1.4, 0.5
			).clamp()

			var floor_tex = TextureGenerator.pick_floor(
				dominant_floor, floor_textures, alt_pattern_chance
			)

			var floor_tile = floor_scene.instantiate()
			maze_container.add_child(floor_tile)
			floor_tile.position = pos
			floor_tile.setup(tile_size, floor_tex, tint, x, z)

			if cell == 1:
				var wall_tex = TextureGenerator.pick_wall(
					dominant_wall, wall_textures, alt_pattern_chance
				)
				var wall = wall_scene.instantiate()
				maze_container.add_child(wall)
				wall.position = pos
				wall.setup(tile_size, wall_height, wall_tex, wall_tint)

			elif cell == 2:
				var checkpoint = checkpoint_scene.instantiate()
				maze_container.add_child(checkpoint)
				checkpoint.position = pos + Vector3(0, 0.8, 0)
				checkpoint.connect("collected", _on_checkpoint_collected)
				total_checkpoints += 1

			elif cell == 3:
				var player = player_scene.instantiate()
				maze_container.add_child(player)
				player.position = pos + Vector3(0, 0.5, 0)

				var cam = get_tree().get_first_node_in_group("camera")
				if cam:
					cam.target = player

				if hud:
					hud.player_node = player

	if hud:
		hud.update_counter(0, total_checkpoints)

func _on_checkpoint_collected():
	collected_checkpoints += 1

	var search_time = snappedf(level_timer_seconds - _cp_search_start, 0.01)
	_cp_search_start = level_timer_seconds

	var player = get_tree().get_first_node_in_group("player")
	var pos    = player.global_position if player else Vector3.ZERO

	EventTracker.record(
		"checkpoint_search_time",
		"cp_%d_of_%d" % [collected_checkpoints, total_checkpoints],
		pos,
		search_time
	)

	EventTracker.record(
		"checkpoint_collected",
		"cp_%d_of_%d" % [collected_checkpoints, total_checkpoints],
		pos
	)

	if hud:
		hud.update_counter(collected_checkpoints, total_checkpoints)
		hud.show_collect_message(collected_checkpoints, total_checkpoints)

	if collected_checkpoints >= total_checkpoints:
		_on_win()

func _on_win():

	if level_ended:
		return

	level_ended = true

	GameSession.carried_time += max(remaining_time, 0.0)

	EventTracker.record("level_complete", algorithm)
	EventTracker.flush()

	HeatmapTracker.save_and_send_level_time(
		college_id,
		current_level + 1,
		pending_size,
		pending_seed,
		level_timer_seconds
	)

	HeatmapTracker.save_and_send_heatmap(
		college_id,
		pending_seed,
		current_level + 1
	)

	_mark_level_complete()

	if hud:
		hud.show_win_message()

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("trigger_victory"):
		player.trigger_victory()

	await get_tree().create_timer(2.0).timeout

	_return_to_menu()

func _on_time_up():

	if level_ended:
		return

	level_ended = true

	# Clamp timer visually
	remaining_time = 0.0

	# Mark level complete even on timeout
	_mark_level_complete()

	EventTracker.record("level_failed_time", algorithm)
	EventTracker.flush()

	HeatmapTracker.save_and_send_level_time(
		college_id,
		current_level + 1,
		pending_size,
		pending_seed,
		level_timer_seconds
	)

	HeatmapTracker.save_and_send_heatmap(
		college_id,
		pending_seed,
		current_level + 1
	)

	if hud:
		hud.update_timer(0)

	if hud and hud.has_method("show_message"):
		hud.show_message("Time Up!")

	await get_tree().create_timer(2.0).timeout

	_return_to_menu()

func _mark_level_complete():
	var field = ""
	match current_level:
		0: field = "level_1_cleared"
		1: field = "level_2_cleared"
		2: field = "level_3_cleared"
		_: return

	var http = HTTPRequest.new()
	add_child(http)

	var url = "%s/rest/v1/participant_sessions?college_id=eq.%s" % [
		SUPABASE_URL, college_id
	]

	var headers = [
		"apikey: " + SUPABASE_API_KEY,
		"Authorization: Bearer " + SUPABASE_API_KEY,
		"Content-Type: application/json",
		"Prefer: return=minimal"
	]

	http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify({ field: true }))

func _return_to_menu():
	get_tree().paused = false
	clear_maze()

	var menu = load("res://scenes/menus/MainMenu.tscn").instantiate()
	menu.college_id = college_id
	menu.auto_login = true

	get_tree().root.add_child(menu)
	queue_free()

#func _input(event: InputEvent):
	#if event.is_action_pressed("ui_cancel"):
		#if not exit_dialog.visible:
			#var player = get_tree().get_first_node_in_group("player")
			#var pos    = player.global_position if player else Vector3.ZERO
#
			#EventTracker.record("button_press", "pause", pos)
			#get_tree().paused = true
			#exit_dialog.popup_centered()

func _process(delta):

	if level_ended:
		return

	if get_tree().paused:
		return

	if maze.is_empty():
		return

	level_timer_seconds += delta
	remaining_time -= delta

	if hud and hud.has_method("update_timer"):
		hud.update_timer(ceil(remaining_time))

	if remaining_time <= 0.0:
		_on_time_up()

func clear_maze():
	for child in get_children():
		child.queue_free()
	hud = null

func clear_level():
	if maze_container:
		maze_container.queue_free()
		maze_container = Node3D.new()
		add_child(maze_container)

func _setup_lighting():
	var top_light = DirectionalLight3D.new()
	add_child(top_light)
	top_light.rotation_degrees = Vector3(-90, 0, 0)
	top_light.light_energy     = 0.5
	top_light.light_color      = Color(1.0, 0.97, 0.90)
	top_light.shadow_enabled   = true

	var env         = WorldEnvironment.new()
	var environment = Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color  = Color(0.3, 0.3, 0.35)
	environment.ambient_light_energy = 0.7
	env.environment = environment
	add_child(env)

func _get_quadrant_tint(x: int, z: int) -> Color:
	var sector_x = maze[0].size() / QUADRANT_DIVISIONS
	var sector_z = maze.size()    / QUADRANT_DIVISIONS
	var col      = min(x / sector_x, QUADRANT_DIVISIONS - 1)
	var row      = min(z / sector_z, QUADRANT_DIVISIONS - 1)
	return QUADRANT_COLORS[row * QUADRANT_DIVISIONS + col]

func _on_exit_confirmed():
	EventTracker.record("button_press", "exit_confirmed")
	EventTracker.flush()
	_return_to_menu()

func _on_exit_canceled():
	EventTracker.record("button_press", "exit_canceled")
	get_tree().paused = false
