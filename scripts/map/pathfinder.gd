class_name Pathfinder
extends RefCounted
## Shortest paths on one floor, using Godot's AStarGrid2D.
## 8-way movement with the same no-corner-cutting rule as the player.

var _astar: AStarGrid2D = AStarGrid2D.new()


func _init(map: MapData) -> void:
	_astar.region = Rect2i(0, 0, map.width, map.height)
	_astar.cell_size = Vector2(1, 1)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if not map.is_walkable(cell):
				_astar.set_point_solid(cell, true)


## First step (a direction) on the shortest path from `from` to `to`,
## or Vector2i.ZERO if there's no path or you're already there.
func next_step(from: Vector2i, to: Vector2i) -> Vector2i:
	if from == to:
		return Vector2i.ZERO
	var path: Array[Vector2i] = _astar.get_id_path(from, to)
	if path.size() < 2:
		return Vector2i.ZERO
	return path[1] - from
