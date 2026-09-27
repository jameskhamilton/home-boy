class_name Fighter
extends Node
## Health for an actor. Damage comes from dice combat (see DiceCombat).

## Emitted when HP changes (for HP bars).
signal hp_changed(hp: int, max_hp: int)
## Emitted once when HP reaches 0.
signal died

@export_range(1, 999) var max_hp: int = 10

var hp: int = 10


func _ready() -> void:
	hp = max_hp


## Back to full health.
func reset() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)


func is_dead() -> bool:
	return hp <= 0


func take_damage(amount: int) -> void:
	if is_dead() or amount <= 0:
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
