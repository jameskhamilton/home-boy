class_name Player
extends Node2D
## The player: lives on a grid cell; the sprite is just drawn there.

## Emitted whenever the player arrives on a cell (moved or placed).
signal moved(cell: Vector2i)

## How far the player can see, in tiles.
@export_range(1, 30) var sight_radius: int = 8

## Logical position in tiles (the source of truth). Pixel position is derived from it.
@export var grid_pos: Vector2i = Vector2i(2, 2)

## The floor the player is on. Set by Main. Used to stop walking into walls.
var map: MapData

@onready var _camera: Camera2D = $Camera2D
@onready var _input: DirectionInput = $DirectionInput


func _ready() -> void:
	_sync_position()
	_input.step_requested.connect(_on_step_requested)


## Handle a step from input. If a diagonal is blocked, slide along the wall by
## taking whichever single direction is open (if exactly one is).
func _on_step_requested(dir: Vector2i) -> void:
	if move(dir):
		return
	if dir.x == 0 or dir.y == 0:
		return
	var horizontal := Vector2i(dir.x, 0)
	var vertical := Vector2i(0, dir.y)
	var can_h: bool = _can_enter(grid_pos + horizontal)
	var can_v: bool = _can_enter(grid_pos + vertical)
	if can_h and not can_v:
		move(horizontal)
	elif can_v and not can_h:
		move(vertical)


## Try to move one tile (including diagonally). Returns false and stays put if
## the target isn't walkable, or if a diagonal would cut past a wall corner.
func move(dir: Vector2i) -> bool:
	var target: Vector2i = grid_pos + dir
	if not _can_enter(target):
		return false
	# Diagonals need both side cells open, so you never clip a wall corner.
	if dir.x != 0 and dir.y != 0 \
			and (not _can_enter(grid_pos + Vector2i(dir.x, 0)) \
			or not _can_enter(grid_pos + Vector2i(0, dir.y))):
		return false
	grid_pos = target
	_sync_position()
	moved.emit(grid_pos)
	return true


## True if the player could stand on this cell (always true with no map).
func _can_enter(cell: Vector2i) -> bool:
	return map == null or map.is_walkable(cell)


## Jump straight to a cell (e.g. the floor's start position).
func place_at(cell: Vector2i) -> void:
	grid_pos = cell
	_sync_position()
	moved.emit(grid_pos)


## Stop the camera scrolling past the map's edges (size in pixels).
func set_camera_limits(map_size_px: Vector2i) -> void:
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map_size_px.x
	_camera.limit_bottom = map_size_px.y


## Grid cell -> pixels. Vector2i * int stays Vector2i, so convert for `position`.
func _sync_position() -> void:
	position = Vector2(grid_pos * GameMap.TILE_SIZE)
