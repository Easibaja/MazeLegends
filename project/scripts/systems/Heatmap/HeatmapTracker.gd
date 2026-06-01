extends Node
var heatmap_visits: Array = []
var heatmap_time: Array = []
var maze_ref: Array = []
var map_width: int = 0
var map_height: int = 0
var current_cell: Vector2i = Vector2i(-1, -1)

const SUPABASE_URL = Env.SUPABASE_URL
const SUPABASE_KEY = Env.SUPABASE_KEY

func initialize(width: int, height: int, maze: Array) -> void:
	map_width = width
	map_height = height
	maze_ref = maze
	current_cell = Vector2i(-1, -1)
	heatmap_visits = []
	heatmap_time = []
	for y in range(height):
		var row_v = []
		var row_t = []
		row_v.resize(width)
		row_t.resize(width)
		row_v.fill(0)
		row_t.fill(0.0)
		heatmap_visits.append(row_v)
		heatmap_time.append(row_t)

func record_visit(gx: int, gz: int) -> void:
	if maze_ref[gz][gx] == 1:
		return
	heatmap_visits[gz][gx] += 1
	current_cell = Vector2i(gx, gz)

func end_visit(gx: int, gz: int) -> void:
	if current_cell == Vector2i(gx, gz):
		current_cell = Vector2i(-1, -1)

func _process(delta: float) -> void:
	if current_cell.x == -1:
		return
	heatmap_time[current_cell.y][current_cell.x] += delta

func print_heatmap() -> void:
	print("=== HEATMAP VISITS ===")
	for y in range(map_height):
		var row = ""
		for x in range(map_width):
			row += "%3d" % heatmap_visits[y][x]
		print(row)
	print("=== HEATMAP TIME (seconds) ===")
	for y in range(map_height):
		var row = ""
		for x in range(map_width):
			row += "%6.2f" % heatmap_time[y][x]
		print(row)

func save_and_send_heatmap(college_id: String, maze_seed: int, level_index: int) -> void:
	var rows = []
	for y in range(map_height):
		for x in range(map_width):
			var visits = heatmap_visits[y][x]
			var time_s = heatmap_time[y][x]
			if visits > 0:
				rows.append({
					"college_id":   college_id,
					"seed":         maze_seed,
					"level_index":  level_index,
					"row":          y,
					"col":          x,
					"visits":       visits,
					"time_seconds": snappedf(time_s, 0.01)
				})
	# TODO: UNCOMMENT THE NEXT LINE DURING EXPERIMENT!!
	_save_csv(rows)
	_send_to_supabase("heatmap_data", rows, "Heatmap")

func _save_csv(rows: Array) -> void:
	var path = "user://heatmap_data.csv"
	var write_mode = FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE
	var file = FileAccess.open(path, write_mode)
	if file == null:
		push_error("[Heatmap] Could not open file: " + path)
		return
	if write_mode == FileAccess.WRITE:
		file.store_line("college_id,seed,level_index,row,col,visits,time_seconds")
	else:
		file.seek_end()
	for row in rows:
		file.store_line("%s,%d,%d,%d,%d,%d,%.2f" % [
			row.college_id, row.seed, row.level_index,
			row.row, row.col, row.visits, row.time_seconds
		])
	file.close()
	print("[Heatmap] Saved to: ", ProjectSettings.globalize_path("user://heatmap_data.csv"))

func save_and_send_level_time(college_id: String, level_index: int, size: int, seed: int, time_seconds: float) -> void:
	var rows = []
	rows.append({
		"college_id":   college_id,
		"level_index":  level_index,
		"size":         size,
		"seed":         seed,
		"time_seconds": snappedf(time_seconds, 0.01)
	})
	# TODO: UNCOMMENT THE NEXT LINE DURING EXPERIMENT!!
	_save_level_time_csv(rows)
	_send_to_supabase("level_time_data", rows, "LevelTime")

func _save_level_time_csv(rows: Array) -> void:
	var path = "user://level_time_data.csv"
	var write_mode = FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE
	var file = FileAccess.open(path, write_mode)
	if file == null:
		push_error("[LevelTime] Could not open file: " + path)
		return
	if write_mode == FileAccess.WRITE:
		file.store_line("college_id,level_index,size,seed,time_seconds")
	else:
		file.seek_end()
	for row in rows:
		file.store_line("%s,%d,%d,%d,%.2f" % [
			row.college_id, row.level_index,
			row.size, row.seed, row.time_seconds
		])
	file.close()
	print("[LevelTime] Saved to: ", ProjectSettings.globalize_path(path))

func _send_to_supabase(table: String, rows: Array, tag: String) -> void:
	var url = SUPABASE_URL + "/rest/v1/" + table
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Prefer: return=minimal"
	]
	var http = HTTPRequest.new()
	Engine.get_main_loop().root.add_child(http)
	http.request_completed.connect(func(_result, code, _headers, _body):
		http.queue_free()
		print("[%s] Supabase response code: %d" % [tag, code])
	)
	var err = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(rows))
	if err != OK:
		push_error("[%s] HTTP request failed: %s" % [tag, str(err)])
		http.queue_free()
