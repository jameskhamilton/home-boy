class_name Action
extends RefCounted
## One thing an actor does on its turn (move, wait, later attack...).
## The player and enemies both produce Actions; TurnManager performs them.

## Who is doing this action.
var actor: Actor


func _init(p_actor: Actor) -> void:
	actor = p_actor


## Carry out the action. Returns true if it used up the actor's turn.
func perform() -> bool:
	return false
