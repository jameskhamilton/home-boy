class_name GameMap
extends Node2D
## Draws a MapData onto the Tiles layer. Holds no game rules - it only renders.

const TILE_SIZE: int = 16
const SOURCE_ID: int = 0
## Atlas slot in art/tiles.png for each MapData.Tile (stable slots, see ROADMAP).
const ATLAS: Dictionary[int, Vector2i] = {
	MapData.Tile.FLOOR: Vector2i(0, 0),
	MapData.Tile.WALL: Vector2i(1, 0),
}

@onready var _tiles: TileMapLayer = $Tiles


## Redraw every cell of the given map.
func draw_map(map: MapData) -> void:
	_tiles.clear()
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			_tiles.set_cell(cell, SOURCE_ID, ATLAS[map.get_tile(cell)])
