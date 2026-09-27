class_name CorridorRouter
extends RefCounted
## Carves corridors between points, choosing the route that avoids running
## alongside existing corridors (no "stripes" of parallel passages).
## Candidate routes: every L- and Z-shaped path between the two points.

## Penalty per new corridor tile that runs next to (1 or 2 tiles from) another corridor.
const PARALLEL_PENALTY: float = 20.0
## Small penalty per bend, so a straight L beats a Z when both are clean.
const TURN_PENALTY: float = 2.0

var _map: MapData
var _rng: RandomNumberGenerator
var _room_mask: PackedByteArray
var _corridor_mask: PackedByteArray


func _init(map: MapData, rng: RandomNumberGenerator) -> void:
	_map = map
	_rng = rng
	_room_mask = PackedByteArray()
	_room_mask.resize(map.width * map.height)
	_corridor_mask = PackedByteArray()
	_corridor_mask.resize(map.width * map.height)


## Record a room's cells so corridors passing through rooms aren't penalised.
func mark_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			_room_mask[_index(Vector2i(x, y))] = 1


## Carve the best route between two points. If `required` is false, the corridor is
## only carved when the best route doesn't run alongside another corridor.
## Returns true if a corridor was carved.
func connect_points(from: Vector2i, to: Vector2i, required: bool) -> bool:
	var best_path: Array[Vector2i] = []
	var best_score: float = INF
	var best_parallel: int = 0
	for candidate in _candidate_paths(from, to):
		var parallel: int = _parallel_count(candidate["path"])
		var score: float = parallel * PARALLEL_PENALTY \
			+ _new_cell_count(candidate["path"]) \
			+ candidate["turns"] * TURN_PENALTY \
			+ _rng.randf() * 0.5 # random tie-break, still seeded
		if score < best_score:
			best_score = score
			best_path = candidate["path"]
			best_parallel = parallel
	if not required and best_parallel > 0:
		return false
	for cell in best_path:
		_map.set_tile(cell, MapData.Tile.FLOOR)
		if _room_mask[_index(cell)] == 0:
			_corridor_mask[_index(cell)] = 1
	return true


## All horizontal-vertical-horizontal and vertical-horizontal-vertical routes.
## (The two plain L-shapes are the cases where the bend is at an end point.)
func _candidate_paths(from: Vector2i, to: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for bx in range(mini(from.x, to.x), maxi(from.x, to.x) + 1):
		var path: Array[Vector2i] = []
		_append_h(path, from.x, bx, from.y)
		_append_v(path, from.y, to.y, bx)
		_append_h(path, bx, to.x, to.y)
		out.append({"path": path, "turns": _turns(bx != from.x, from.y != to.y, bx != to.x)})
	for by in range(mini(from.y, to.y), maxi(from.y, to.y) + 1):
		var path: Array[Vector2i] = []
		_append_v(path, from.y, by, from.x)
		_append_h(path, from.x, to.x, by)
		_append_v(path, by, to.y, to.x)
		out.append({"path": path, "turns": _turns(by != from.y, from.x != to.x, by != to.y)})
	return out


## Number of bends in a 3-segment path, given which segments have length > 0.
func _turns(a: bool, b: bool, c: bool) -> int:
	var segments: int = int(a) + int(b) + int(c)
	return maxi(segments - 1, 0)


## How many new corridor cells would sit 1-2 tiles beside an existing corridor,
## measured across the direction of travel (so crossing a corridor costs nothing).
func _parallel_count(path: Array[Vector2i]) -> int:
	var count: int = 0
	for i in path.size():
		var cell: Vector2i = path[i]
		var idx: int = _index(cell)
		if _room_mask[idx] == 1 or _corridor_mask[idx] == 1:
			continue
		var dir: Vector2i = _direction_at(path, i)
		var side: Vector2i = Vector2i(dir.y, dir.x).abs() # perpendicular
		for dist: int in [1, 2]:
			if _is_corridor(cell + side * dist) or _is_corridor(cell - side * dist):
				count += 1
				break
	return count


## Direction of travel at step i (uses the next step, or the previous one at the end).
func _direction_at(path: Array[Vector2i], i: int) -> Vector2i:
	if i + 1 < path.size():
		return path[i + 1] - path[i]
	if i > 0:
		return path[i] - path[i - 1]
	return Vector2i.RIGHT


## New floor tiles this path would add (shorter is better).
func _new_cell_count(path: Array[Vector2i]) -> int:
	var count: int = 0
	for cell in path:
		if not _map.is_walkable(cell):
			count += 1
	return count


func _is_corridor(cell: Vector2i) -> bool:
	return _map.in_bounds(cell) and _corridor_mask[_index(cell)] == 1


func _index(cell: Vector2i) -> int:
	return cell.y * _map.width + cell.x


## Append a horizontal run (skipping a duplicate start cell).
func _append_h(path: Array[Vector2i], x1: int, x2: int, y: int) -> void:
	var step: int = 1 if x2 >= x1 else -1
	for x in range(x1, x2 + step, step):
		var c := Vector2i(x, y)
		if path.is_empty() or path.back() != c:
			path.append(c)


## Append a vertical run (skipping a duplicate start cell).
func _append_v(path: Array[Vector2i], y1: int, y2: int, x: int) -> void:
	var step: int = 1 if y2 >= y1 else -1
	for y in range(y1, y2 + step, step):
		var c := Vector2i(x, y)
		if path.is_empty() or path.back() != c:
			path.append(c)
