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
## Health and combat stats (a child node named "Fighter"), or null.
var fighter: Fighter


func _ready() -> void:
	fighter = get_node_or_null("Fighter") as Fighter
	_sync_position()


## Name used in the message log, e.g. "the pale snake" or "you".
func display_name() -> String:
	return "it"


## Verb for a landed attack in the log, e.g. "bites".
func attack_verb() -> String:
	return "hits"


## Verb for a missed attack in the log, e.g. "misses".
func miss_verb() -> String:
	return "misses"


## True if an attack in `dir` is allowed: someone is there, and a diagonal
## attack doesn't reach round a wall corner (same rule as moving).
func can_attack(dir: Vector2i) -> bool:
	if world == null or world.actor_at(grid_pos + dir) == null:
		return false
	if dir.x != 0 and dir.y != 0 and map != null:
		if not map.is_walkable(grid_pos + Vector2i(dir.x, 0)) \
				or not map.is_walkable(grid_pos + Vector2i(0, dir.y)):
			return false
	return true


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
