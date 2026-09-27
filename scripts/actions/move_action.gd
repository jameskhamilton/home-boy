class_name MoveAction
extends Action
## Step one tile in a direction (diagonals allowed, with the no-corner-cutting rule).

var direction: Vector2i


func _init(p_actor: Actor, p_direction: Vector2i) -> void:
	super(p_actor)
	direction = p_direction


func perform() -> bool:
	return actor.move(direction)
