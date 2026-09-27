class_name Player
extends Node2D
## The player: lives on a grid cell; the sprite is just drawn there.

## Logical position in tiles (the source of truth). Pixel position is derived from it.
@export var grid_pos: Vector2i = Vector2i(2, 2)

## The floor the player is on. Set by Main. Used to stop walking into walls.
var map: MapData

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	_sync_position()


func _unhandled_input(event: InputEvent) -> void:
	var dir: Vector2i = Vector2i.ZERO
	# true = allow key-repeat, so holding a key keeps moving.
	if event.is_action_pressed("move_up", true):
		dir = Vector2i.UP
	elif event.is_action_pressed("move_down", true):
		dir = Vector2i.DOWN
	elif event.is_action_pressed("move_left", true):
		dir = Vector2i.LEFT
	elif event.is_action_pressed("move_right", true):
		dir = Vector2i.RIGHT

	if dir != Vector2i.ZERO:
		move(dir)
		get_viewport().set_input_as_handled()


## Try to move one tile. Returns false (and stays put) if the target isn't walkable.
func move(dir: Vector2i) -> bool:
	var target: Vector2i = grid_pos + dir
	if map != null and not map.is_walkable(target):
		return false
	grid_pos = target
	_sync_position()
	return true


## Jump straight to a cell (e.g. the floor's start position).
func place_at(cell: Vector2i) -> void:
	grid_pos = cell
	_sync_position()


## Stop the camera scrolling past the map's edges (size in pixels).
func set_camera_limits(map_size_px: Vector2i) -> void:
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map_size_px.x
	_camera.limit_bottom = map_size_px.y


## Grid cell -> pixels. Vector2i * int stays Vector2i, so convert for `position`.
func _sync_position() -> void:
	position = Vector2(grid_pos * GameMap.TILE_SIZE)
