class_name Actor
extends Node2D
## Anything that lives on the grid and takes turns: the player and enemies.
## Holds the logical grid position; the node's pixel position is derived from it.

## Emitted whenever the actor arrives on a cell (moved or placed).
signal moved(cell: Vector2i)

## How far this actor can see, in tiles.
@export_range(1, 30) var sight_radius: int = 8
## Logical position in tiles (the source of truth).
@export var grid_pos: Vector2i = Vector2i.ZERO

## The floor this actor is on. Set when the floor is entered.
var map: MapData
## Who else is on the floor (for blocking). Set when the floor is entered.
var world: TurnManager


func _ready() -> void:
	_sync_position()


## True if this actor could stand on the cell: floor, and nobody else there.
func can_enter(cell: Vector2i) -> bool:
	if map != null and not map.is_walkable(cell):
		return false
	if world != null:
		var other: Actor = world.actor_at(cell)
		if other != null and other != self:
			return false
	return true


## True if a one-tile step in `dir` is allowed. Diagonals need both side cells
## to be floor, so nobody clips a wall corner.
func can_step(dir: Vector2i) -> bool:
	if not can_enter(grid_pos + dir):
		return false
	if dir.x != 0 and dir.y != 0 and map != null:
		if not map.is_walkable(grid_pos + Vector2i(dir.x, 0)) \
				or not map.is_walkable(grid_pos + Vector2i(0, dir.y)):
			return false
	return true


## Step one tile if allowed. Returns true if the actor moved.
func move(dir: Vector2i) -> bool:
	if not can_step(dir):
		return false
	grid_pos += dir
	_sync_position()
	moved.emit(grid_pos)
	return true


## Jump straight to a cell (e.g. a spawn point).
func place_at(cell: Vector2i) -> void:
	grid_pos = cell
	_sync_position()
	moved.emit(grid_pos)


## Grid cell -> pixels.
func _sync_position() -> void:
	position = Vector2(grid_pos * GameMap.TILE_SIZE)
