class_name CombatRequest
extends RefCounted
## A fight waiting to be played out once the current action finishes.

var enemy: Enemy
## The sloth started it while camouflaged: it gets an extra die for the whole fight.
var ambush: bool
## A snake caught the sloth napping: it gets a free first round at double damage.
var caught_napping: bool


func _init(p_enemy: Enemy, p_ambush: bool, p_caught_napping: bool) -> void:
	enemy = p_enemy
	ambush = p_ambush
	caught_napping = p_caught_napping
