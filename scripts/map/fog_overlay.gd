class_name FogOverlay
extends Node2D
## Darkens the map by field of view: unexplored = solid dark, explored but
## out of sight = dimmed, in sight = clear. Drawn over the terrain, under actors.

## Palette colour 'k' (#1b1420), the darkest in the game.
const UNEXPLORED: Color = Color("#1b1420")
const REMEMBERED: Color = Color("#1b1420", 0.6)

## The map to read visibility from. Set by GameMap.
var map: MapData


func _draw() -> void:
	if map == null:
		return
	var size: Vector2 = Vector2(GameMap.TILE_SIZE, GameMap.TILE_SIZE)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if map.is_visible(cell):
				continue
			var colour: Color = REMEMBERED if map.is_explored(cell) else UNEXPLORED
			draw_rect(Rect2(Vector2(cell * GameMap.TILE_SIZE), size), colour)
