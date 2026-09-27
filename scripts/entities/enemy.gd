class_name Enemy
extends Actor
## A monster on the grid. Stats come from its MonsterDef; decisions from its EnemyAI child.
## Only drawn while the player can see its cell.

const HUNT_COLOUR: Color = Color("#b13e53")   # palette 'r'
const SEARCH_COLOUR: Color = Color("#e8b04a") # palette 'y'
const REST_COLOUR: Color = Color("#7e7892")   # palette 'W'

## What kind of monster this is. Set before adding to the scene.
@export var def: MonsterDef

@onready var ai: EnemyAI = $EnemyAI
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _state_label: Label = $StateLabel


func _ready() -> void:
	super()
	if def != null:
		_sprite.frame_coords = def.atlas_coords
		sight_radius = def.sight_radius
		if fighter != null:
			fighter.max_hp = def.max_hp
			fighter.reset()
	show_state(EnemyAI.State.WANDER)


## Diggers (moles) can tunnel into any wall except the map's outer edge.
func can_enter(cell: Vector2i) -> bool:
	if def != null and def.digs and map != null and _is_inner(cell):
		var other: Actor = world.actor_at(cell) if world != null else null
		return other == null or other == self
	return super(cell)


## Diggers ignore the no-corner-cutting rule (they just dig).
func can_step(dir: Vector2i) -> bool:
	if def != null and def.digs:
		return can_enter(grid_pos + dir)
	return super(dir)


## Moving into a wall digs it out first.
func move(dir: Vector2i) -> bool:
	if not can_step(dir):
		return false
	var target: Vector2i = grid_pos + dir
	if def != null and def.digs and not map.is_walkable(target):
		map.set_tile(target, MapData.Tile.FLOOR)
		world.cell_dug.emit(target)
	return super(dir)


func _is_inner(cell: Vector2i) -> bool:
	return cell.x > 0 and cell.y > 0 and cell.x < map.width - 1 and cell.y < map.height - 1


func display_name() -> String:
	return "the " + (def.display_name if def != null else "monster")


func attack_verb() -> String:
	return "bites"


## Update the marker above the enemy: "!" hunting, "?" searching, "z" resting, nothing otherwise.
func show_state(state: EnemyAI.State) -> void:
	match state:
		EnemyAI.State.HUNT:
			_state_label.text = "!"
			_state_label.add_theme_color_override("font_color", HUNT_COLOUR)
		EnemyAI.State.SEARCH:
			_state_label.text = "?"
			_state_label.add_theme_color_override("font_color", SEARCH_COLOUR)
		EnemyAI.State.REST:
			_state_label.text = "z"
			_state_label.add_theme_color_override("font_color", REST_COLOUR)
		_:
			_state_label.text = ""


## Show the enemy only if the player can currently see where it stands.
func refresh_visibility() -> void:
	visible = map != null and map.is_visible(grid_pos)
