class_name ItemDef
extends Resource
## Something small lying on the floor that takes effect when you walk over it.
## New items = new .tres in data/items/ (then add them to Catalog.ITEMS).

enum Effect {
	HEAL,       ## Restore HP (healing fruit; the hammock adds more). Left behind if you're full.
	LUCKY_DIE,  ## +amount dice in your next fight (lucky pebble).
	XP,         ## +amount carried XP (glow moss).
}

@export var id: StringName = &"item"
@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var effect: Effect = Effect.XP
@export var amount: int = 1
## Frame (column, row) in art/items.png.
@export var atlas_coords: Vector2i = Vector2i(1, 0)
