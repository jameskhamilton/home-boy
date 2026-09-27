class_name UpgradeDef
extends Resource
## Something the sloth can order on the computer at home, paid for with banked XP.
## New upgrades = new .tres files in data/upgrades/ (then add them to Catalog).

enum Kind {
	EXTRA_REROLL,  ## +1 reroll per combat round.
	EXTRA_DIE,     ## Roll one more sloth die.
	SHELL_TO_CLAW, ## One shell face on every sloth die becomes a claw.
	SHELL_TO_LEAF, ## One shell face on every sloth die becomes a leaf.
	MAX_HP,        ## +2 max HP.
}

@export var id: StringName = &"upgrade"
@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.MAX_HP
## Price of the first one, in XP.
@export_range(0, 999) var base_cost: int = 5
## Each extra purchase costs this much more.
@export_range(0, 999) var cost_step: int = 5
## How many times it can be bought.
@export_range(1, 20) var max_count: int = 3
