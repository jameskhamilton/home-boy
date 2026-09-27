class_name FurnitureDef
extends Resource
## A piece of furniture found underground. Carried home, it shows in the tree house
## and gives a lasting bonus. New furniture = a new .tres (then add it to Catalog).

enum Bonus {
	NAP_HEAL,   ## Naps heal this much extra per turn.
	SIGHT,      ## +sight radius.
	MAX_HP,     ## +max HP.
	FIGHT_XP,   ## +XP for every fight won.
	CAMO_SPEED, ## Camouflage takes this many fewer turns.
}

@export var id: StringName = &"furniture"
@export var display_name: String = "Furniture"
@export_multiline var description: String = ""
@export var bonus: Bonus = Bonus.MAX_HP
@export var amount: int = 1
## Shallowest floor it can be found on.
@export_range(1, 20) var min_depth: int = 1
## Picture in the tree house, and where its top-left corner goes (home scene pixels).
@export var texture: Texture2D
@export var home_position: Vector2 = Vector2.ZERO
