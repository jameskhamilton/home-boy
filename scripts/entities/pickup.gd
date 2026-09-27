class_name Pickup
extends Sprite2D
## Something lying on the floor: a furniture crate (carry it home to keep it)
## or a small item (takes effect when you walk over it).

const ITEMS_TEXTURE: Texture2D = preload("res://art/items.png")

## Exactly one of these is set.
var furniture: FurnitureDef
var item: ItemDef
var grid_pos: Vector2i


func _init(p_furniture: FurnitureDef, p_item: ItemDef, cell: Vector2i) -> void:
	furniture = p_furniture
	item = p_item
	grid_pos = cell
	texture = ITEMS_TEXTURE
	centered = false
	region_enabled = true
	var frame: Vector2i = item.atlas_coords if item != null else Vector2i(0, 0)
	region_rect = Rect2(frame * 16, Vector2(16, 16))
	position = Vector2(cell * GameMap.TILE_SIZE)


## Shown once the player has seen its cell.
func refresh_visibility(map: MapData) -> void:
	visible = map.is_explored(grid_pos)
