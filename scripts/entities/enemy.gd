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
			fighter.load_from(def)
	if fighter != null:
		fighter.died.connect(_on_died)
	show_state(EnemyAI.State.WANDER)


func display_name() -> String:
	return "the " + (def.display_name if def != null else "monster")


func attack_verb() -> String:
	return "bites"


func _on_died() -> void:
	world.enemy_died(self)


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
