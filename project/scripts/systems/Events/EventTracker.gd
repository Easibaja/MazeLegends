extends Node

const SUPABASE_URL = Env.SUPABASE_URL
const SUPABASE_KEY = Env.SUPABASE_KEY

var college_id:   String = ""
var maze_seed:    int    = 0
var level_index:  int    = 0
var tile_size:    float  = 2.0

var _buffer:      Array = []
var _level_timer: float = 0.0

func set_session(p_id: String, m_seed: int, l_index: int, t_size: float) -> void:
	college_id   = p_id
	maze_seed    = m_seed
	level_index  = l_index
	tile_size    = t_size
	_level_timer = 0.0
	_buffer.clear()

func _process(delta: float) -> void:
	_level_timer += delta

func record(
	event_type:  String,
	event_label: String,
	world_pos:   Vector3 = Vector3(-1, -1, -1),
	event_value: float   = NAN
) -> void:
	var row_i = -1
	var col_i = -1
	if world_pos != Vector3(-1, -1, -1) and tile_size > 0:
		col_i = int(round(world_pos.x / tile_size))
		row_i = int(round(world_pos.z / tile_size))

	var value = _level_timer if is_nan(event_value) else event_value

	_buffer.append({
		"college_id":  college_id,
		"seed":        maze_seed,
		"level_index": level_index,
		"event_type":  event_type,
		"event_label": event_label,
		"pos_row":     row_i,
		"pos_col":     col_i,
		"event_value": snappedf(value, 0.01)
	})

func flush() -> void:
	if _buffer.is_empty():
		return
	var rows = _buffer.duplicate()
	_save_csv(rows)
	_send_to_supabase("event_data", rows, "Event")
	_buffer.clear()

func _save_csv(rows: Array) -> void:
	var path = "user://event_data.csv"
	var write_mode = FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE
	var file = FileAccess.open(path, write_mode)
	if file == null:
		push_error("[Event] Could not open file: " + path)
		return
	if write_mode == FileAccess.WRITE:
		file.store_line("college_id,seed,level_index,event_type,event_label,pos_row,pos_col,event_value")
	else:
		file.seek_end()
	for row in rows:
		file.store_line("%s,%d,%d,%s,%s,%d,%d,%.2f" % [
			row.college_id, row.seed, row.level_index,
			row.event_type, row.event_label,
			row.pos_row, row.pos_col, row.event_value
		])
	file.close()
	print("[Event] Saved to: ", ProjectSettings.globalize_path(path))

func _send_to_supabase(table: String, rows: Array, tag: String) -> void:
	var url = SUPABASE_URL + "/rest/v1/" + table
	var headers = [
		"Content-Type: application/json",
		"apikey: "               + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Prefer: return=minimal"
	]
	var http = HTTPRequest.new()
	Engine.get_main_loop().root.add_child(http)
	http.request_completed.connect(func(_result, code, _headers, body):
		http.queue_free()
		print("[%s] Supabase response: %d" % [tag, code])
		if code != 201:
			print("[%s] Error body: %s" % [tag, body.get_string_from_utf8()])
	)
	var err = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(rows))
	if err != OK:
		push_error("[%s] HTTP request failed: %s" % [tag, str(err)])
		http.queue_free()
