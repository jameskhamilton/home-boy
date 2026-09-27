class_name Pickup
extends Sprite2D
## A furniture crate lying on the floor. Walk onto it to carry it (bring it home to keep it).

const ITEMS_TEXTURE: Texture2D = preload("res://art/items.png")

var furniture: FurnitureDef
var grid_pos: Vector2i


func _init(p_furniture: FurnitureDef, cell: Vector2i) -> void:
	furniture = p_furniture
	grid_pos = cell
	texture = ITEMS_TEXTURE
	centered = false
	region_enabled = true
	region_rect = Rect2(0, 0, 16, 16)
	position = Vector2(cell * GameMap.TILE_SIZE)


## Shown once the player has seen its cell.
func refresh_visibility(map: MapData) -> void:
	visible = map.is_explored(grid_pos)
