class_name NapAction
extends WaitAction
## Nap for a turn: heal 1 HP. Counts as waiting, so it also builds camouflage.


func perform() -> bool:
	actor.fighter.heal(1)
	return true
