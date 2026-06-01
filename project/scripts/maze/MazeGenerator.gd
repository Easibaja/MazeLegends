class_name MazeGenerator

# ─────────────────────────────────────────────────────────────
# RECURSIVE BACKTRACKING
# ─────────────────────────────────────────────────────────────

static func generate_recursive_backtracking(size: int, maze_seed: int, checkpoints_num: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = maze_seed

	var maze = []
	for y in range(size):
		maze.append([])
		for x in range(size):
			maze[y].append(1)

	maze[1][1] = 0
	_carve(maze, size, 1, 1, rng)
	maze[1][1] = 3

	_place_checkpoints(maze, size, checkpoints_num)
	return maze


static func _carve(maze: Array, size: int, x: int, y: int, rng: RandomNumberGenerator) -> void:
	var dirs = [
		Vector2(2, 0),
		Vector2(-2, 0),
		Vector2(0, 2),
		Vector2(0, -2)
	]

	_shuffle_with_rng(dirs, rng)

	for dir in dirs:
		var nx = x + int(dir.x)
		var ny = y + int(dir.y)

		if nx > 0 and ny > 0 and nx < size - 1 and ny < size - 1:
			if maze[ny][nx] == 1:
				maze[y + int(dir.y / 2)][x + int(dir.x / 2)] = 0
				maze[ny][nx] = 0
				_carve(maze, size, nx, ny, rng)

static func _shuffle_with_rng(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

# ─────────────────────────────────────────────────────────────
# RECURSIVE DIVISION
# ─────────────────────────────────────────────────────────────

static func generate_division(size: int, maze_seed: int, checkpoints_num: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = maze_seed

	var maze = []
	for y in range(size):
		maze.append([])
		for x in range(size):
			maze[y].append(1)

	for y in range(1, size, 2):
		for x in range(1, size, 2):
			maze[y][x] = 0

	var cols = (size - 1) / 2
	var rows = (size - 1) / 2

	var owner = []
	for r in range(rows):
		owner.append([])
		for c in range(cols):
			owner[r].append(-1)

	var num_blobs = max(2, (cols * rows) / 8)
	num_blobs = min(num_blobs, cols * rows)

	var all_rooms = []
	for r in range(rows):
		for c in range(cols):
			all_rooms.append(Vector2i(c, r))

	_shuffle_with_rng(all_rooms, rng)

	var frontiers = []
	for b in range(num_blobs):
		var seed_cell = all_rooms[b]
		owner[seed_cell.y][seed_cell.x] = b
		frontiers.append(_blob_neighbors(seed_cell.x, seed_cell.y, cols, rows))

	var growing = true
	while growing:
		var claims = []

		for b in range(num_blobs):
			for cell in frontiers[b]:
				if owner[cell.y][cell.x] == -1:
					claims.append({"b": b, "c": cell.x, "r": cell.y})

		if claims.size() == 0:
			break

		_shuffle_with_rng(claims, rng)

		for claim in claims:
			if owner[claim.r][claim.c] == -1:
				owner[claim.r][claim.c] = claim.b

		for b in range(num_blobs):
			frontiers[b] = []

		for r in range(rows):
			for c in range(cols):
				var b = owner[r][c]
				if b == -1:
					continue
				for nb in _blob_neighbors(c, r, cols, rows):
					if owner[nb.y][nb.x] == -1:
						frontiers[b].append(nb)

	for r in range(rows):
		for c in range(cols - 1):
			if owner[r][c] == owner[r][c + 1]:
				maze[2 * r + 1][2 * c + 2] = 0

	for r in range(rows - 1):
		for c in range(cols):
			if owner[r][c] == owner[r + 1][c]:
				maze[2 * r + 2][2 * c + 1] = 0

	for r in range(rows - 1):
		for c in range(cols - 1):
			var a = owner[r][c]
			if a == owner[r][c + 1] and a == owner[r + 1][c] and a == owner[r + 1][c + 1]:
				maze[2 * r + 2][2 * c + 2] = 0

	var uf = []
	for i in range(num_blobs):
		uf.append(i)

	var inter_edges = []
	for r in range(rows):
		for c in range(cols):
			var a = owner[r][c]

			if c + 1 < cols:
				var b = owner[r][c + 1]
				if a != b:
					inter_edges.append({"a": a, "b": b, "wc": 2 * c + 2, "wr": 2 * r + 1})

			if r + 1 < rows:
				var b2 = owner[r + 1][c]
				if a != b2:
					inter_edges.append({"a": a, "b": b2, "wc": 2 * c + 1, "wr": 2 * r + 2})

	_shuffle_with_rng(inter_edges, rng)

	for edge in inter_edges:
		var ra = _uf_find(uf, edge.a)
		var rb = _uf_find(uf, edge.b)

		if ra != rb:
			uf[ra] = rb
			maze[edge.wr][edge.wc] = 0

	maze[1][1] = 3
	_place_checkpoints(maze, size, checkpoints_num)
	return maze

static func _blob_neighbors(c: int, r: int, cols: int, rows: int) -> Array:
	var out = []
	if c > 0:        out.append(Vector2i(c - 1, r))
	if c < cols - 1: out.append(Vector2i(c + 1, r))
	if r > 0:        out.append(Vector2i(c, r - 1))
	if r < rows - 1: out.append(Vector2i(c, r + 1))
	return out


static func _uf_find(uf: Array, x: int) -> int:
	while uf[x] != x:
		uf[x] = uf[uf[x]]
		x = uf[x]
	return x

# ─────────────────────────────────────────────────────────────
# SIDEWINDER
# ─────────────────────────────────────────────────────────────

static func generate_sidewinder(size: int, maze_seed: int, checkpoints_num: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = maze_seed

	var maze = []
	for y in range(size):
		maze.append([])
		for x in range(size):
			maze[y].append(1)

	maze[1][1] = 0
	_carve_sw(maze, size, rng)
	maze[1][1] = 3

	_place_checkpoints(maze, size, checkpoints_num)
	return maze


static func _carve_sw(maze: Array, size: int, rng: RandomNumberGenerator) -> void:
	for y in range(1, size, 2):
		var run = []

		for x in range(1, size, 2):
			maze[y][x] = 0
			run.append(Vector2i(x, y))

			var at_eastern_boundary = (x >= size - 2)
			var at_northern_boundary = (y == 1)
			var should_close_out = at_eastern_boundary or (not at_northern_boundary and rng.randi() % 2 == 0)

			if should_close_out:
				var member = run[rng.randi_range(0, run.size() - 1)]
				if member.y > 1:
					maze[member.y - 1][member.x] = 0
				run.clear()
			else:
				maze[y][x + 1] = 0

# ─────────────────────────────────────────────────────────────
# CHECKPOINT PLACERS
# ─────────────────────────────────────────────────────────────

static func _bfs_distances(maze: Array, size: int, start: Vector2) -> Dictionary:
	var dist = {}
	var queue = [start]
	dist[start] = 0
	while queue.size() > 0:
		var current = queue.pop_front()
		var neighbors = [
			Vector2(current.x + 1, current.y),
			Vector2(current.x - 1, current.y),
			Vector2(current.x, current.y + 1),
			Vector2(current.x, current.y - 1),
		]
		for n in neighbors:
			if n.x >= 0 and n.y >= 0 and n.x < size and n.y < size:
				if not dist.has(n) and maze[int(n.y)][int(n.x)] == 0:
					dist[n] = dist[current] + 1
					queue.append(n)
	return dist

static func _place_checkpoints(maze: Array, size: int, count: int) -> void:
	var open_cells = []
	for y in range(1, size - 1):
		for x in range(1, size - 1):
			if maze[y][x] == 0:
				open_cells.append(Vector2(x, y))

	var start = Vector2(1, 1)
	var placed = [start]
	var dist_maps = [_bfs_distances(maze, size, start)]

	for i in range(count):
		var best_cell = null
		var best_score = -1
		for cell in open_cells:
			var min_dist = INF
			for dm in dist_maps:
				var d = dm.get(cell, -1)
				if d != -1 and d < min_dist:
					min_dist = d
			if min_dist > best_score:
				best_score = min_dist
				best_cell = cell
		if best_cell != null:
			placed.append(best_cell)
			dist_maps.append(_bfs_distances(maze, size, best_cell))
			maze[int(best_cell.y)][int(best_cell.x)] = 2
