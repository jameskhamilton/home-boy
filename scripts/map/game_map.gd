class_name GameMap
extends Node2D
## Draws a MapData: the Tiles layer for terrain and the Fog overlay for field of view.
## Holds no game rules - it only renders.

const TILE_SIZE: int = 16
const SOURCE_ID: int = 0
## Atlas slot in art/tiles.png for each MapData.Tile (stable slots, see ROADMAP).
const ATLAS: Dictionary[int, Vector2i] = {
	MapData.Tile.FLOOR: Vector2i(0, 0),
	MapData.Tile.WALL: Vector2i(1, 0),
	MapData.Tile.LADDER_UP: Vector2i(2, 0),
	MapData.Tile.STAIRS_DOWN: Vector2i(3, 0),
}

@onready var _tiles: TileMapLayer = $Tiles
@onready var _fog: FogOverlay = $Fog


## Redraw every cell of the given map.
func draw_map(map: MapData) -> void:
	_tiles.clear()
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			_tiles.set_cell(cell, SOURCE_ID, ATLAS[map.get_tile(cell)])
	_fog.map = map
	refresh_fog()


## Redraw the fog after the field of view changes.
func refresh_fog() -> void:
	_fog.queue_redraw()


## Redraw one cell (e.g. after a mole digs through a wall).
func redraw_cell(map: MapData, cell: Vector2i) -> void:
	_tiles.set_cell(cell, SOURCE_ID, ATLAS[map.get_tile(cell)])
