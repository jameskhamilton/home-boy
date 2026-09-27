class_name Fighter
extends Node
## Combat stats and health for an actor. Attacks roll to hit, then roll damage.

## Emitted when HP changes (for HP bars).
signal hp_changed(hp: int, max_hp: int)
## Emitted once when HP reaches 0.
signal died

@export_range(1, 999) var max_hp: int = 10
## Chance (0-1) that an attack lands.
@export_range(0.0, 1.0) var accuracy: float = 0.75
@export_range(0, 99) var damage_min: int = 1
@export_range(0, 99) var damage_max: int = 3
## Subtracted from each hit taken (a hit always does at least 1).
@export_range(0, 99) var defence: int = 0

var hp: int = 10


func _ready() -> void:
	hp = max_hp


## Copy stats from a MonsterDef (enemies) and reset HP.
func load_from(def: MonsterDef) -> void:
	max_hp = def.max_hp
	accuracy = def.accuracy
	damage_min = def.damage_min
	damage_max = def.damage_max
	defence = def.defence
	reset()


## Back to full health.
func reset() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)


func is_dead() -> bool:
	return hp <= 0


## Roll damage for one hit against `target` (before any multiplier).
func roll_damage(target: Fighter, rng: RandomNumberGenerator) -> int:
	return maxi(1, rng.randi_range(damage_min, damage_max) - target.defence)


func take_damage(amount: int) -> void:
	if is_dead():
		return
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()


## Heal up to max. Returns how much was actually healed.
func heal(amount: int) -> int:
	var before: int = hp
	hp = mini(max_hp, hp + amount)
	if hp != before:
		hp_changed.emit(hp, max_hp)
	return hp - before
