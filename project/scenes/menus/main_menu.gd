extends Control

@export var maze_scene: PackedScene

const SUPABASE_URL = Env.SUPABASE_URL
const SUPABASE_API_KEY = Env.SUPABASE_KEY

const CHECKPOINT_SCENE = preload("res://scenes/environment/checkpoint.tscn")
const MAY_SCENE        = preload("res://scenes/player/MayCharacter.tscn")
var PIXEL_FONT       = preload("res://assets/Pixelta.ttf")

var college_id: String = ""
var valid_ids = {}
var algorithm:  String = ""

var auto_login := false

var level_1_cleared := false
var level_2_cleared := false
var level_3_cleared := false

var center_container: CenterContainer
var container: Control

var id_input:    LineEdit
var error_label: Label

var bg: TextureRect

# ── Rotation state for animated viewports ─────────────────────────────────────
var _rotating_mays: Array = []

const ROTATE_INTERVAL = 2.5
const ROTATE_STEP_DEG = 90.0
const ROTATE_SPEED    = 4.0

# ══════════════════════════════════════════════════════════════════════════════
#  LOAD PARTICIPANT IDs
# ══════════════════════════════════════════════════════════════════════════════

func _load_local_ids():
	var file = FileAccess.open("res://participant_ids.json", FileAccess.READ)

	if file == null:
		push_error("Failed to open .json file")
		return

	var content = file.get_as_text()
	var data = JSON.parse_string(content)

	if typeof(data) != TYPE_ARRAY:
		push_error("Invalid JSON format (expected array)")
		return

	valid_ids.clear()

	for id in data:
		valid_ids[id] = true

	print("participant IDs loaded successfully:", valid_ids.size())


# ══════════════════════════════════════════════════════════════════════════════
#  READY / PROCESS
# ══════════════════════════════════════════════════════════════════════════════
func _ready():
	_load_local_ids()
	PIXEL_FONT.antialiasing         = TextServer.FONT_ANTIALIASING_NONE
	PIXEL_FONT.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	_build_login_ui()
	_fade_in()

	if auto_login and college_id != "":
		id_input.text = college_id
		_on_id_entered()


func _process(delta: float) -> void:
	for entry in _rotating_mays:
		var may: Node3D = entry["may"]
		if not is_instance_valid(may):
			continue

		entry["timer"] -= delta
		if entry["timer"] <= 0.0:
			entry["timer"]        = ROTATE_INTERVAL
			entry["target_angle"] = entry["target_angle"] + ROTATE_STEP_DEG

		var current = entry["current_angle"]
		var target  = entry["target_angle"]
		var new_angle = lerp_angle(
			deg_to_rad(current),
			deg_to_rad(target),
			clamp(ROTATE_SPEED * delta, 0.0, 1.0)
		)
		entry["current_angle"]  = rad_to_deg(new_angle)
		may.rotation_degrees.y  = rad_to_deg(new_angle)


# ══════════════════════════════════════════════════════════════════════════════
#  HELPER
# ══════════════════════════════════════════════════════════════════════════════
func _apply_pixel_font(node: Control, size: int = 16) -> void:
	node.add_theme_font_override("font", PIXEL_FONT)
	node.add_theme_font_size_override("font_size", size)


# ══════════════════════════════════════════════════════════════════════════════
#  LOGIN UI
# ══════════════════════════════════════════════════════════════════════════════
func _build_login_ui():
	_clear_ui()
	_rotating_mays.clear()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)

	bg = TextureRect.new()
	bg.texture = load("res://assets/newback.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.set_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 20)
	center_container.add_child(container)

	var title = Label.new()
	title.text = ""
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#e6e600"))
	_apply_pixel_font(title, 56)
	container.add_child(title)

	id_input = LineEdit.new()
	id_input.placeholder_text    = "Enter College ID"
	id_input.custom_minimum_size = Vector2(260, 40)
	_apply_pixel_font(id_input, 16)
	id_input.text_submitted.connect(func(_text): _on_id_entered())
	container.add_child(id_input)

	error_label = Label.new()
	error_label.visible = false
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_apply_pixel_font(error_label, 14)
	container.add_child(error_label)

	var btn = Button.new()
	btn.text                = "Continue"
	btn.custom_minimum_size = Vector2(260, 50)
	btn.pressed.connect(_on_id_entered)
	_apply_pixel_font(btn, 18)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color               = Color("#1c5419")
	btn_style.corner_radius_top_left     = 8
	btn_style.corner_radius_top_right    = 8
	btn_style.corner_radius_bottom_left  = 8
	btn_style.corner_radius_bottom_right = 8

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color               = Color("#267322")
	btn_hover.corner_radius_top_left     = 8
	btn_hover.corner_radius_top_right    = 8
	btn_hover.corner_radius_bottom_left  = 8
	btn_hover.corner_radius_bottom_right = 8

	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover",  btn_hover)
	container.add_child(btn)


# ══════════════════════════════════════════════════════════════════════════════
#  LOGIN LOGIC
# ══════════════════════════════════════════════════════════════════════════════

func _is_valid_id(id: String) -> bool:
	id = id.strip_edges().to_upper()
	return valid_ids.has(id)

func _on_id_entered():
	var id = id_input.text.strip_edges().to_upper()
	error_label.visible = false

	if id == "":
		_show_error("Please enter an ID")
		return
	
	if not _is_valid_id(id):
		_show_error("Invalid ID")
		return
	
	if id == "ADMIN":
		college_id = id
		algorithm  = "backtracking"
		_show_admin_menu()
		return

	college_id = id
	_assign_algorithm()


func _assign_algorithm():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_assign_algorithm_response)

	var url     = "%s/rest/v1/rpc/assign_algorithm" % SUPABASE_URL
	var headers = [
		"apikey: " + SUPABASE_API_KEY,
		"Authorization: Bearer " + SUPABASE_API_KEY,
		"Content-Type: application/json"
	]
	var body = JSON.stringify({ "p_college_id": college_id })
	var err  = http.request(url, headers, HTTPClient.METHOD_POST, body)

	if err != OK:
		_show_error("Failed to contact server")


func _on_assign_algorithm_response(result, response_code, headers, body):
	var text = body.get_string_from_utf8()

	print("===== ASSIGN ALGORITHM RESPONSE =====")
	print("Result: ", result)
	print("HTTP Code: ", response_code)
	print("Headers: ", headers)
	print("Body length: ", text.length())
	print("Body:")
	print(text)
	print("====================================")

	if response_code != 200:
		_show_error("Failed to assign algorithm")
		return

	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_STRING:
		print("Parsed type was: ", typeof(parsed))
		_show_error("Invalid server response")
		return

	algorithm = parsed
	print("Assigned algorithm: ", algorithm, " HELP!")

	_fetch_progress()


func _fetch_progress():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_progress_response)

	var url = "%s/rest/v1/participant_sessions?college_id=eq.%s&select=*" % [
		SUPABASE_URL, college_id
	]
	var headers = [
		"apikey: " + SUPABASE_API_KEY,
		"Authorization: Bearer " + SUPABASE_API_KEY,
		"Accept: application/json",
		"Accept-Encoding: identity"
	]
	var err = http.request(url, headers, HTTPClient.METHOD_GET)

	print("Progress request err: ", err)
	print("Progress URL: ", url)

	if err != OK:
		_show_error("Failed to fetch progress")


func _on_progress_response(result, response_code, headers, body):
	print("RESULT:", result)

	match result:
		HTTPRequest.RESULT_SUCCESS:
			print("SUCCESS")
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			print("CHUNKED_BODY_SIZE_MISMATCH")
		HTTPRequest.RESULT_CANT_CONNECT:
			print("CANT_CONNECT")
		HTTPRequest.RESULT_CANT_RESOLVE:
			print("CANT_RESOLVE")
		HTTPRequest.RESULT_CONNECTION_ERROR:
			print("CONNECTION_ERROR")
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			print("TLS_HANDSHAKE_ERROR")
		_:
			print("UNKNOWN RESULT")

	var text = body.get_string_from_utf8()

	print("===== PROGRESS RESPONSE =====")
	print("Result: ", result)
	print("HTTP Code: ", response_code)
	print("Headers: ", headers)
	print("Body length: ", text.length())
	print("Body:")
	print(text)
	print("================================")

	if response_code != 200:
		_show_error("Failed to load progress")
		return

	var parsed = JSON.parse_string(text)

	if parsed == null:
		print("JSON PARSE FAILED")
		print("Raw text was:")
		print(text)
		_show_error("JSON parse failed")
		return

	if typeof(parsed) != TYPE_ARRAY:
		print("Expected ARRAY but got type: ", typeof(parsed))
		_show_error("Invalid progress data")
		return

	if parsed.is_empty():
		_show_error("Participant not found")
		return

	var data = parsed[0]

	print("Participant data:")
	print(data)

	level_1_cleared = data["level_1_cleared"]
	level_2_cleared = data["level_2_cleared"]
	level_3_cleared = data["level_3_cleared"]

	_show_level_select()


# ══════════════════════════════════════════════════════════════════════════════
#  LEVEL SELECT
# ══════════════════════════════════════════════════════════════════════════════
func _show_level_select():
	_rotating_mays.clear()

	var tween = create_tween()
	tween.tween_property(bg, "modulate:a", 0.0, 0.2)
	await tween.finished
	bg.texture = load("res://assets/newbacknotitle.png")
	tween = create_tween()
	tween.tween_property(bg, "modulate:a", 1.0, 0.2)

	container.queue_free()

	var root = HBoxContainer.new()
	root.add_theme_constant_override("separation", 60)
	center_container.add_child(root)

	# ══ LEFT PANEL ════════════════════════════════════════════════════════════
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color                   = Color(0.0, 0.0, 0.0, 1.0)
	glow_style.border_color               = Color("#e6e600")
	glow_style.border_width_left          = 2
	glow_style.border_width_right         = 2
	glow_style.border_width_top           = 2
	glow_style.border_width_bottom        = 2
	glow_style.corner_radius_top_left     = 12
	glow_style.corner_radius_top_right    = 12
	glow_style.corner_radius_bottom_left  = 12
	glow_style.corner_radius_bottom_right = 12
	glow_style.shadow_color = Color(1.0, 0.9, 0.0, 0.15)
	glow_style.shadow_size  = 0
	glow_style.content_margin_left        = 16
	glow_style.content_margin_right       = 16
	glow_style.content_margin_top         = 16
	glow_style.content_margin_bottom      = 16

	var glow_panel = PanelContainer.new()
	glow_panel.add_theme_stylebox_override("panel", glow_style)
	root.add_child(glow_panel)

	# Animate border shadow glow only
	var glow_tween = create_tween().set_loops()
	glow_tween.tween_method(func(a: float):
		glow_style.shadow_color = Color(1.0, 0.9, 0.0, a)
		glow_style.shadow_size  = int(a * 16.0)
	, 0.15, 0.6, 1.2)
	glow_tween.tween_method(func(a: float):
		glow_style.shadow_color = Color(1.0, 0.9, 0.0, a)
		glow_style.shadow_size  = int(a * 16.0)
	, 0.6, 0.15, 1.2)

	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(800, 0)
	left.alignment           = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 16)
	glow_panel.add_child(left)

	var left_vbox = left

	var how_label = Label.new()
	how_label.text                 = "★ How to Play ★"
	how_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how_label.add_theme_color_override("font_color", Color("#e6e600"))
	_apply_pixel_font(how_label, 32)
	left.add_child(how_label)

	var vp_defs = [
		{ "label": "Navigate the maze — collect all checkpoints!\nThe arrow points to the nearest one.", "anim": "idle",  "rotate": false },
		{ "label": "WASD / Arrow Keys — Move",            "anim": "walk",  "rotate": true  },
		{ "label": "SHIFT — Toggle Run\nEach level has a timer — unused time carries over!", "anim": "run",   "rotate": true  },
	]

	for def in vp_defs:
		_add_viewport_row(left_vbox, def["label"], def["anim"], def["rotate"])

	# ══ RIGHT PANEL ═══════════════════════════════════════════════════════════
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(280, 0)
	right.alignment           = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 20)
	root.add_child(right)

	_add_level_button(right, "Level 1", 0, true,            level_1_cleared)
	_add_level_button(right, "Level 2", 1, level_1_cleared, level_2_cleared)
	_add_level_button(right, "Level 3", 2, level_2_cleared, level_3_cleared)
	_add_questionnaire_button(right)


# ══════════════════════════════════════════════════════════════════════════════
#  VIEWPORT ROW BUILDER
# ══════════════════════════════════════════════════════════════════════════════
func _add_viewport_row(parent: Control, label_text: String, anim: String, rotate: bool) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var sv_container = SubViewportContainer.new()
	sv_container.custom_minimum_size   = Vector2(360, 220)
	sv_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sv_container.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	sv_container.stretch               = true
	row.add_child(sv_container)

	var sv = SubViewport.new()
	sv.size                       = Vector2i(260, 160)
	sv.render_target_update_mode  = SubViewport.UPDATE_ALWAYS
	sv.transparent_bg             = false
	sv.own_world_3d               = true
	sv_container.add_child(sv)

	_build_sv_scene(sv, anim, rotate)

	var lbl = Label.new()
	lbl.text                  = label_text
	lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	lbl.add_theme_color_override("font_color", Color("#dddddd"))
	_apply_pixel_font(lbl, 24)
	row.add_child(lbl)


# ══════════════════════════════════════════════════════════════════════════════
#  SUBVIEWPORT SCENE BUILDER
# ══════════════════════════════════════════════════════════════════════════════
func _build_sv_scene(sv: SubViewport, anim: String, rotate: bool) -> void:
	var world_env = WorldEnvironment.new()
	var env       = Environment.new()
	env.background_mode      = Environment.BG_COLOR
	env.background_color     = Color(0.08, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.3, 0.3, 0.4)
	env.ambient_light_energy = 1.2
	world_env.environment    = env
	sv.add_child(world_env)

	var dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-45, 30, 0)
	dir_light.light_energy     = 1.4
	dir_light.light_color      = Color(1.0, 0.95, 0.85)
	dir_light.shadow_enabled   = false
	sv.add_child(dir_light)

	var floor_body  = StaticBody3D.new()
	var floor_mesh  = MeshInstance3D.new()
	var floor_plane = PlaneMesh.new()
	floor_plane.size             = Vector2(10, 10)
	floor_mesh.mesh              = floor_plane
	var floor_mat                = StandardMaterial3D.new()
	floor_mat.albedo_color       = Color(0.2, 0.18, 0.15)
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)
	var floor_col   = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(10, 0.1, 10)
	floor_col.shape  = floor_shape
	floor_body.add_child(floor_col)
	sv.add_child(floor_body)

	var cam = Camera3D.new()
	cam.fov              = 20.0
	cam.near             = 0.1
	cam.far              = 1000.0
	cam.rotation_degrees = Vector3(-65, 0, 0)
	sv.add_child(cam)

	match anim:
		"walk":
			cam.position = Vector3(0.0, 4.98, 2.32)
			var may_walk = MAY_SCENE.instantiate()
			may_walk.set_script(null)
			may_walk.position = Vector3(0.0, 0.02, 0.0)
			sv.add_child(may_walk)
			var anim_walk: Node3D = may_walk.get_node("Idle")
			anim_walk._play_anim(anim_walk.ANIM_WALK)
			if rotate:
				_rotating_mays.append({
					"may":           may_walk,
					"timer":         ROTATE_INTERVAL,
					"current_angle": 0.0,
					"target_angle":  0.0,
				})
		"run":
			cam.position = Vector3(0.0, 4.98, 2.32)
			var may_run = MAY_SCENE.instantiate()
			may_run.set_script(null)
			may_run.position = Vector3(0.0, 0.02, 0.0)
			sv.add_child(may_run)
			var anim_run: Node3D = may_run.get_node("Idle")
			anim_run._play_anim(anim_run.ANIM_RUN)
			if rotate:
				_rotating_mays.append({
					"may":           may_run,
					"timer":         ROTATE_INTERVAL,
					"current_angle": 0.0,
					"target_angle":  0.0,
				})
		"idle":
			cam.position = Vector3(0.0, 4.98, 2.32)

			while true:
				var cycle_root = Node3D.new()
				sv.add_child(cycle_root)

				var checkpoint = CHECKPOINT_SCENE.instantiate()
				checkpoint.position = Vector3(0.0, 0.5, 0.0)
				cycle_root.add_child(checkpoint)

				var may_idle = MAY_SCENE.instantiate()
				may_idle.set_script(null)
				may_idle.position = Vector3(-3.0, 0.02, 0.0)
				may_idle.rotation_degrees.y = 90.0
				cycle_root.add_child(may_idle)

				var anim_idle: Node3D = may_idle.get_node("Idle")
				anim_idle._play_anim(anim_idle.ANIM_WALK)

				# ── Arrow overlay ──────────────────────────────────────────────────
				var arrow = ArrowOverlay.new(cam, may_idle, checkpoint, sv.size)
				sv.add_child(arrow)
				# ──────────────────────────────────────────────────────────────────

				var tween = may_idle.create_tween()
				tween.tween_property(may_idle, "position", Vector3(0.0, 0.02, 0.0), 2.5)
				await tween.finished

				# Fade arrow out on arrival
				if is_instance_valid(arrow):
					var fade = arrow.create_tween()
					fade.tween_property(arrow, "modulate:a", 0.0, 0.4)

				await get_tree().physics_frame

				if is_instance_valid(anim_idle):
					anim_idle._play_anim(anim_idle.ANIM_VICTORY)

				await get_tree().create_timer(2.0).timeout

				if is_instance_valid(cycle_root):
					cycle_root.queue_free()
				if is_instance_valid(arrow):
					arrow.queue_free()

				await get_tree().process_frame

# ── Arrow overlay for the idle SubViewport preview ────────────────────────────
class ArrowOverlay extends Control:
	var _cam:        Camera3D
	var _may:        Node3D
	var _checkpoint: Node3D
	var _vp_size:    Vector2
	var pulse_time:  float = 0.0

	func _init(cam: Camera3D, may: Node3D, cp: Node3D, vp_size: Vector2i) -> void:
		_cam        = cam
		_may        = may
		_checkpoint = cp
		_vp_size    = Vector2(vp_size)
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		pulse_time += delta
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(_cam) or not is_instance_valid(_may) or not is_instance_valid(_checkpoint):
			return

		var from_screen := _cam.unproject_position(_may.global_position)
		var to_screen   := _cam.unproject_position(_checkpoint.global_position)

		var dir  := (to_screen - from_screen).normalized()
		var dist := _may.global_position.distance_to(_checkpoint.global_position)

		var pulse  := (sin(pulse_time * 3.0) + 1.0) / 2.0
		var t: float = 1.0 - clamp((dist - 0.5) / 4.0, 0.0, 1.0)

		var length := 28.0 + t * 16.0 + pulse * 4.0
		var head   := 14.0 + t * 6.0  + pulse * 1.5
		var alpha  := 0.7  + t * 0.2  + pulse * 0.1

		var radius := 22.0
		var origin := from_screen + dir * radius
		var angle  := dir.angle()

		draw_set_transform(origin, angle, Vector2.ONE)

		var col_core    := Color(1.0, 0.85, 0.0, alpha).lerp(Color(1.0, 0.1, 0.0, alpha), t)
		var col_outline := Color(0.2, 0.1, 0.0, alpha * 0.8)
		var col_glow    := Color(1.0, 0.6, 0.0, alpha * 0.25)
		var col_white   := Color(1.0, 1.0, 0.85, alpha * 0.6)

		var shaft := PackedVector2Array([
			Vector2(0,             -5.0),
			Vector2(length - head, -5.0),
			Vector2(length - head,  5.0),
			Vector2(0,              5.0),
		])
		var head_pts := PackedVector2Array([
			Vector2(length,         0),
			Vector2(length - head,  head * 0.85),
			Vector2(length - head, -head * 0.85),
		])

		for i in range(3):
			draw_line(Vector2(0, 0), Vector2(length, 0),
				Color(col_glow.r, col_glow.g, col_glow.b, col_glow.a * (0.4 - i * 0.1)),
				16.0 - i * 4.0)

		draw_colored_polygon(shaft,    col_outline)
		draw_colored_polygon(head_pts, col_outline)
		draw_colored_polygon(shaft,    col_core)
		draw_colored_polygon(head_pts, col_core)
		draw_line(Vector2(2, -2.5), Vector2(length - head - 2, -2.5), col_white, 2.0)


# ══════════════════════════════════════════════════════════════════════════════
#  LEVEL BUTTONS
# ══════════════════════════════════════════════════════════════════════════════
func _add_level_button(parent, text, level_index, unlocked, completed):
	var btn = Button.new()
	btn.text                = text
	btn.disabled            = not unlocked or completed
	btn.custom_minimum_size = Vector2(260, 60)
	_apply_pixel_font(btn, 18)

	var style       = StyleBoxFlat.new()
	var hover_style = StyleBoxFlat.new()

	btn.pressed.connect(func():
		_start_game(level_index)
	)

	if completed:
		style.bg_color = Color("#8A90B8")
		btn.text      += " ✓"
	elif unlocked:
		style.bg_color       = Color("#1c5419")
		hover_style.bg_color = Color("#267322")
	else:
		style.bg_color = Color("#8A90B8")

	for s in [style, hover_style]:
		s.corner_radius_top_left     = 8
		s.corner_radius_top_right    = 8
		s.corner_radius_bottom_left  = 8
		s.corner_radius_bottom_right = 8

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover",  hover_style)
	parent.add_child(btn)


func _add_questionnaire_button(parent):
	var btn = Button.new()
	btn.text                = "Exit"
	btn.disabled            = true
	btn.custom_minimum_size = Vector2(260, 50)
	_apply_pixel_font(btn, 16)

	var style       = StyleBoxFlat.new()
	var hover_style = StyleBoxFlat.new()

	btn.pressed.connect(func():
		get_tree().quit()
	)

	style.bg_color       = Color("#8A90B8")
	hover_style.bg_color = Color("#8A90B8")

	for s in [style, hover_style]:
		s.corner_radius_top_left     = 8
		s.corner_radius_top_right    = 8
		s.corner_radius_bottom_left  = 8
		s.corner_radius_bottom_right = 8

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover",  hover_style)
	parent.add_child(btn)

	# Enable 10 seconds after level 3 is cleared
	if level_3_cleared:
		await get_tree().create_timer(5.0).timeout
		if is_instance_valid(btn):
			btn.disabled             = false
			style.bg_color           = Color("#7A1F2B")
			hover_style.bg_color     = Color("#A52A3A")

# ══════════════════════════════════════════════════════════════════════════════
#  ADMIN MENU
# ══════════════════════════════════════════════════════════════════════════════
func _show_admin_menu():
	container.queue_free()

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(vbox)

	_add_admin_button(vbox, "Backtracking", "backtracking")
	_add_admin_button(vbox, "Sidewinder",   "sidewinder")
	_add_admin_button(vbox, "Division",     "division")


func _add_admin_button(parent, text, algo):
	var btn = Button.new()
	btn.text                = text
	btn.custom_minimum_size = Vector2(260, 60)
	_apply_pixel_font(btn, 18)
	btn.pressed.connect(func():
		algorithm = algo
		_start_game(0)
	)
	parent.add_child(btn)


# ══════════════════════════════════════════════════════════════════════════════
#  GAME START / UTILITIES
# ══════════════════════════════════════════════════════════════════════════════
func _start_game(level_index: int):
	var maze_instance           = maze_scene.instantiate()
	maze_instance.algorithm     = algorithm
	maze_instance.college_id    = college_id
	maze_instance.current_level = level_index
	get_tree().root.add_child(maze_instance)
	queue_free()


func _show_error(msg: String):
	error_label.text    = msg
	error_label.visible = true


func _fade_in():
	modulate.a = 0.0
	var tween  = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _clear_ui():
	for child in get_children():
		child.queue_free()
