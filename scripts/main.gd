extends Node2D
## Wires the game together: builds the floor, draws it, and places the player.

@onready var _game_map: GameMap = $GameMap
@onready var _player: Player = $Player

var map: MapData


func _ready() -> void:
	map = MapData.from_text(HandmadeMaps.TEST_FLOOR)
	_game_map.draw_map(map)
	_player.map = map
	_player.place_at(map.player_start)
	_player.set_camera_limits(Vector2i(map.width, map.height) * GameMap.TILE_SIZE)
	print("Map %dx%d loaded, player at %s" % [map.width, map.height, map.player_start])
