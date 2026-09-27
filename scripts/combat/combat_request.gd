class_name CombatRequest
extends RefCounted
## A fight waiting to be played out once the current action finishes.

var enemy: Enemy
## The sloth started it while camouflaged: it gets an extra die for the whole fight.
var ambush: bool


func _init(p_enemy: Enemy, p_ambush: bool) -> void:
	enemy = p_enemy
	ambush = p_ambush
