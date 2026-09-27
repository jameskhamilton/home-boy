class_name MapData
extends RefCounted
## One dungeon floor as plain data: a width x height grid of tile types.
## This is the source of truth for the map. GameMap only draws it.

enum Tile { FLOOR, WALL }

var width: int
var height: int
## Where the player starts on this floor (in tiles).
var player_start: Vector2i = Vector2i.ZERO

var _tiles: PackedByteArray


func _init(w: int, h: int, fill: Tile = Tile.WALL) -> void:
	width = w
	height = h
	_tiles = PackedByteArray()
	_tiles.resize(w * h)
	_tiles.fill(fill)


## True if the cell is inside the map.
func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## Tile type at a cell. Anything outside the map counts as wall.
func get_tile(cell: Vector2i) -> Tile:
	if not in_bounds(cell):
		return Tile.WALL
	return _tiles[cell.y * width + cell.x] as Tile


## Change the tile type at a cell (ignored if out of bounds).
func set_tile(cell: Vector2i, tile: Tile) -> void:
	if in_bounds(cell):
		_tiles[cell.y * width + cell.x] = tile


## True if an actor can stand on this cell.
func is_walkable(cell: Vector2i) -> bool:
	return get_tile(cell) == Tile.FLOOR


## Build a map from text: '#' wall, '.' floor, '@' floor + player start.
## Lines must all be the same length.
static func from_text(text: String) -> MapData:
	var lines: PackedStringArray = text.strip_edges().split("\n")
	var h: int = lines.size()
	var w: int = lines[0].strip_edges().length()
	var map: MapData = MapData.new(w, h)
	for y in h:
		var line: String = lines[y].strip_edges()
		assert(line.length() == w, "Map line %d is %d wide, expected %d" % [y, line.length(), w])
		for x in w:
			var ch: String = line[x]
			var cell := Vector2i(x, y)
			if ch == "#":
				map.set_tile(cell, Tile.WALL)
			else:
				map.set_tile(cell, Tile.FLOOR)
				if ch == "@":
					map.player_start = cell
	return map
