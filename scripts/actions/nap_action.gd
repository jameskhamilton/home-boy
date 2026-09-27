class_name NapAction
extends WaitAction
## Nap for a turn: heal (1 HP, more with a hammock at home). Counts as waiting,
## so it also builds camouflage.


func perform() -> bool:
	var amount: int = (actor as Player).nap_heal if actor is Player else 1
	actor.fighter.heal(amount)
	return true
