extends CanvasLayer

var checkpoint_label: Label
var collect_label: Label
var fade_tween: Tween
var arrow_control: Control
var player_node: Node3D
var _nearest_checkpoint: Node3D
var timer_label: Label

var PIXEL_FONT = load("res://assets/Pixelta.ttf")

func _apply_pixel_font(node: Control, size: int = 16) -> void:
	node.add_theme_font_override("font", PIXEL_FONT)
	node.add_theme_font_size_override("font_size", size)

func _ready():
	PIXEL_FONT.antialiasing         = TextServer.FONT_ANTIALIASING_NONE
	PIXEL_FONT.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	_build_ui()

func _build_ui():

	# --- TIMER ---
	timer_label = Label.new()
	timer_label.text = "Time: 00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	timer_label.position.y = 12
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	_apply_pixel_font(timer_label, 24)
	add_child(timer_label)

	# --- CHECKPOINT COUNTER ---
	checkpoint_label = Label.new()
	checkpoint_label.text = "0 / 0"
	checkpoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkpoint_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	checkpoint_label.position.y = 44
	checkpoint_label.add_theme_color_override("font_color", Color(1, 1, 1))
	checkpoint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	checkpoint_label.add_theme_constant_override("shadow_offset_x", 2)
	checkpoint_label.add_theme_constant_override("shadow_offset_y", 2)
	_apply_pixel_font(checkpoint_label, 20)
	add_child(checkpoint_label)

	# --- COLLECT MESSAGE ---
	collect_label = Label.new()
	collect_label.text = ""
	collect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collect_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	collect_label.position.y = 78
	collect_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	collect_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	collect_label.add_theme_constant_override("shadow_offset_x", 2)
	collect_label.add_theme_constant_override("shadow_offset_y", 2)
	collect_label.modulate.a = 0.0
	_apply_pixel_font(collect_label, 28)
	add_child(collect_label)

	# --- CHECKPOINT ARROW ---
	arrow_control = ArrowControl.new()
	arrow_control.set_anchors_preset(Control.PRESET_CENTER)
	arrow_control.pivot_offset = Vector2(0, 0)
	add_child(arrow_control)

func update_timer(seconds_left: float):

	var secs: int = maxi(int(ceil(seconds_left)), 0)

	var minutes: int = secs / 60
	var seconds: int = secs % 60

	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

	if secs <= 10:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif secs <= 30:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	else:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

func _process(_delta: float) -> void:
	if player_node == null or arrow_control == null:
		return
	_nearest_checkpoint = _get_nearest_checkpoint()
	if _nearest_checkpoint == null:
		arrow_control.visible = false
		return
	arrow_control.visible = true
	var dist := player_node.global_position.distance_to(_nearest_checkpoint.global_position)
	arrow_control.distance = dist
	_point_arrow_to(_nearest_checkpoint.global_position)
	arrow_control.queue_redraw()

func _get_nearest_checkpoint() -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for cp in get_tree().get_nodes_in_group("checkpoints"):
		if cp is Node3D:
			var d := player_node.global_position.distance_to(cp.global_position)
			if d < best_dist:
				best_dist = d
				best = cp
	return best

func _point_arrow_to(world_pos: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var p_screen := camera.unproject_position(player_node.global_position)
	var t_screen := camera.unproject_position(world_pos)

	var direction := (t_screen - p_screen).normalized()
	var radius := 30.0

	arrow_control.position = p_screen + direction * radius
	arrow_control.rotation = direction.angle()

func update_counter(collected: int, total: int):
	checkpoint_label.text = "Checkpoints: %d / %d" % [collected, total]

func show_collect_message(collected: int, total: int):
	collect_label.text = "Checkpoint collected!  %d / %d" % [collected, total]
	if fade_tween:
		fade_tween.kill()
	collect_label.modulate.a = 1.0
	fade_tween = create_tween()
	fade_tween.tween_interval(2.0)
	fade_tween.tween_property(collect_label, "modulate:a", 0.0, 0.8)

func show_win_message():
	if fade_tween:
		fade_tween.kill()
	collect_label.modulate.a = 1.0
	collect_label.text = "You escaped the maze!"
	collect_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))

# ---- Arrow drawing node ----
class ArrowControl extends Control:
	var distance: float = 999.0
	var pulse_time: float = 0.0

	func _process(delta: float) -> void:
		pulse_time += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := (sin(pulse_time * 3.0) + 1.0) / 2.0

		var min_dist := 1.0
		var max_dist := 50.0
		var t: float = 1.0 - clamp((distance - min_dist) / (max_dist - min_dist), 0.0, 1.0)

		var length := 36.0 + t * 24.0 + pulse * 6.0
		var head   := 18.0 + t * 8.0  + pulse * 2.0
		var alpha  := 0.7  + t * 0.2  + pulse * 0.1

		var col_white   := Color(1.0,  1.0,  0.85, alpha * 0.6)
		var col_outline := Color(0.2,  0.1,  0.0,  alpha * 0.8)
		var col_core := Color(1.0, 0.85, 0.0, alpha).lerp(Color(1.0, 0.1, 0.0, alpha), t)
		var col_glow := Color(1.0, 0.6,  0.0, alpha * 0.25).lerp(Color(1.0, 0.0, 0.0, alpha * 0.25), t)

		var shaft_points := PackedVector2Array([
			Vector2(0,             -7.0),
			Vector2(length - head, -7.0),
			Vector2(length - head,  7.0),
			Vector2(0,              7.0),
		])

		var head_points := PackedVector2Array([
			Vector2(length,         0),
			Vector2(length - head,  head * 0.85),
			Vector2(length - head, -head * 0.85),
		])

		# Glow layers
		for i in range(3):
			draw_line(Vector2(0, 0), Vector2(length, 0),
				Color(col_glow.r, col_glow.g, col_glow.b, col_glow.a * (0.4 - i * 0.1)),
				22.0 - i * 5.0)

		# Outline
		var shaft_out := PackedVector2Array([
			Vector2(-1,                -8.5),
			Vector2(length - head + 1, -8.5),
			Vector2(length - head + 1,  8.5),
			Vector2(-1,                 8.5),
		])
		draw_colored_polygon(shaft_out,   Color(0, 0, 0, alpha * 0.4))
		draw_colored_polygon(head_points, col_outline)

		# Core arrow
		draw_colored_polygon(shaft_points, col_core)
		draw_colored_polygon(head_points,  col_core)

		# Inner highlight streak
		draw_line(
			Vector2(2, -3.0),
			Vector2(length - head - 2, -3.0),
			col_white, 2.5
		)
