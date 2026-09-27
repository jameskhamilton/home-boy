class_name MonsterDef
extends Resource
## Data for one kind of monster. A new monster = a new .tres in data/monsters/, not new code.

@export var display_name: String = "Monster"
## Frame (column, row) in art/actors.png.
@export var atlas_coords: Vector2i = Vector2i(0, 1)
## How far it can see, in tiles.
@export_range(1, 30) var sight_radius: int = 6
## Turns spent poking around where it last saw you before giving up.
@export_range(0, 50) var search_turns: int = 6
## Turns it can chase before it has to stop and rest (0 = never tires).
@export_range(0, 50) var chase_stamina: int = 8
## Turns it stands still once tired (including the turn it tires). Your window to get out of sight.
@export_range(0, 20) var rest_turns: int = 3
## While searching it only moves every Nth turn (2 = half pace). Gives you time to slip away.
@export_range(1, 5) var search_pace: int = 2

@export_group("Combat")
@export_range(1, 999) var max_hp: int = 6
## Chance (0-1) that its bite lands.
@export_range(0.0, 1.0) var accuracy: float = 0.7
@export_range(0, 99) var damage_min: int = 1
@export_range(0, 99) var damage_max: int = 3
@export_range(0, 99) var defence: int = 0
## XP the sloth gains for defeating it.
@export_range(0, 999) var xp_value: int = 5
