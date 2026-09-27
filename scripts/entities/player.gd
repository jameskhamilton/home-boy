extends Node2D
## The player: lives on a grid cell; the sprite is just drawn there.

const TILE_SIZE: int = 16

## Logical position in tiles (the source of truth). Pixel position is derived from it.
@export var grid_pos: Vector2i = Vector2i(2, 2)


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


## Move one tile. Later (Milestone 3) this will check the map for walls first.
func move(dir: Vector2i) -> void:
	grid_pos += dir
	_sync_position()


## Grid cell -> pixels. Vector2i * int stays Vector2i, so convert for `position`.
func _sync_position() -> void:
	position = Vector2(grid_pos * TILE_SIZE)
