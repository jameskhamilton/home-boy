extends Node2D
## Wires the game together: builds a floor, draws it, and places the player.

## Settings for the dungeon generator (edit the .tres to tune floors).
@export var dungeon_config: DungeonConfig
## Non-zero replays that exact floor; 0 = a new random seed each run.
@export var fixed_seed: int = 0
## Use the hand-made M3 test floor instead of generating one.
@export var use_test_floor: bool = false

@onready var _game_map: GameMap = $GameMap
@onready var _player: Player = $Player
@onready var _seed_label: Label = $HUD/SeedLabel

var map: MapData
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	# Background outside the map = palette 'k'. Also in Project Settings; set here so it can't drift.
	RenderingServer.set_default_clear_color(FogOverlay.UNEXPLORED)
	_player.moved.connect(_on_player_moved)
	var seed_value: int = fixed_seed if fixed_seed != 0 else randi()
	new_floor(seed_value)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_new_floor"):
		new_floor(randi())
		get_viewport().set_input_as_handled()


## Build, draw and enter a floor from the given seed.
func new_floor(seed_value: int) -> void:
	rng.seed = seed_value
	if use_test_floor:
		map = MapData.from_text(HandmadeMaps.TEST_FLOOR)
	else:
		map = DungeonGenerator.generate(dungeon_config, rng)
	_game_map.draw_map(map)
	_player.map = map
	_player.place_at(map.player_start)
	_player.set_camera_limits(Vector2i(map.width, map.height) * GameMap.TILE_SIZE)
	_seed_label.text = "Seed %d" % seed_value
	print("Floor %dx%d, %d rooms, seed %d" % [map.width, map.height, map.rooms.size(), seed_value])


## Every time the player lands on a cell, update what they can see.
func _on_player_moved(cell: Vector2i) -> void:
	map.update_fov(cell, _player.sight_radius)
	_game_map.refresh_fog()



