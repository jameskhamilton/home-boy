class_name DungeonConfig
extends Resource
## Tunable settings for DungeonGenerator.
## Edit data/dungeon/default_dungeon.tres in the Inspector to change how floors feel.

## Floor size in tiles.
@export var map_size: Vector2i = Vector2i(80, 48)
## The floor is split into a grid of zones; each zone holds at most one room.
## More zones = more, smaller-spaced rooms.
@export_range(1, 20) var zone_columns: int = 5
@export_range(1, 20) var zone_rows: int = 4
## Chance (0-1) that a zone gets a room. Lower = emptier floors with longer corridors.
@export_range(0.0, 1.0) var room_chance: float = 0.8
## Smallest room side, in tiles (floor area, not counting walls).
@export_range(3, 30) var room_size_min: int = 5
## Largest room side, in tiles (also capped by zone size).
@export_range(3, 30) var room_size_max: int = 13
## Chance (0-1) of an extra corridor between neighbouring rooms, creating loops.
@export_range(0.0, 1.0) var extra_loop_chance: float = 0.15
