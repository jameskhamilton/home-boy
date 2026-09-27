class_name FOV
extends RefCounted
## Field of view by recursive shadowcasting: which cells can be seen from a point.
## Walls block sight but are themselves visible. Works per octant (8 slices of a circle).
## Reusable for anything that "sees" (the player now, enemies from M6).

# Octant transforms: each column maps the scan's (dx, dy) into map directions.
const _XX: Array[int] = [1, 0, 0, -1, -1, 0, 0, 1]
const _XY: Array[int] = [0, 1, -1, 0, 0, -1, 1, 0]
const _YX: Array[int] = [0, 1, 1, 0, 0, -1, -1, 0]
const _YY: Array[int] = [1, 0, 0, 1, -1, 0, 0, -1]


## Returns the set of visible cells (as dictionary keys) from `origin` within `radius`.
static func compute(map: MapData, origin: Vector2i, radius: int) -> Dictionary[Vector2i, bool]:
	var visible: Dictionary[Vector2i, bool] = {origin: true}
	for octant in 8:
		_cast(map, origin, radius, 1, 1.0, 0.0,
			_XX[octant], _XY[octant], _YX[octant], _YY[octant], visible)
	return visible


## Scan one octant row by row, recursing past each wall to handle the shadow it casts.
static func _cast(map: MapData, origin: Vector2i, radius: int, row: int,
		start_slope: float, end_slope: float,
		xx: int, xy: int, yx: int, yy: int, visible: Dictionary[Vector2i, bool]) -> void:
	if start_slope < end_slope:
		return
	# radius^2 + radius gives a rounder circle than radius^2 alone.
	var radius_sq: int = radius * radius + radius
	var new_start: float = 0.0
	for j in range(row, radius + 1):
		var dx: int = -j - 1
		var dy: int = -j
		var blocked: bool = false
		while dx <= 0:
			dx += 1
			var cell := Vector2i(origin.x + dx * xx + dy * xy, origin.y + dx * yx + dy * yy)
			var left_slope: float = (dx - 0.5) / (dy + 0.5)
			var right_slope: float = (dx + 0.5) / (dy - 0.5)
			if start_slope < right_slope:
				continue
			if end_slope > left_slope:
				break
			if dx * dx + dy * dy <= radius_sq and map.in_bounds(cell):
				visible[cell] = true
			var opaque: bool = not map.is_walkable(cell)
			if blocked:
				if opaque:
					new_start = right_slope
					continue
				blocked = false
				start_slope = new_start
			elif opaque and j < radius:
				blocked = true
				_cast(map, origin, radius, j + 1, start_slope, left_slope, xx, xy, yx, yy, visible)
				new_start = right_slope
		if blocked:
			break
