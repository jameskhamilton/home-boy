class_name MeleeAction
extends Action
## Attack whoever is in the adjacent cell in `direction`.
## Rolls to hit (attacker's accuracy), then rolls damage. A sleeping target is
## always hit for double damage and wakes up.

var direction: Vector2i


func _init(p_actor: Actor, p_direction: Vector2i) -> void:
	super(p_actor)
	direction = p_direction


func perform() -> bool:
	var world: TurnManager = actor.world
	var target: Actor = world.actor_at(actor.grid_pos + direction)
	if target == null or target.fighter == null or actor.fighter == null:
		return false
	var rng: RandomNumberGenerator = world.rng
	var attacker_name: String = actor.display_name()
	var target_name: String = target.display_name()
	var asleep: bool = target is Player and (target as Player).napping

	if not asleep and rng.randf() >= actor.fighter.accuracy:
		world.post_message("%s %s %s." % [_cap(attacker_name), actor.miss_verb(), target_name], MessageColours.MISS)
		return true

	var damage: int = actor.fighter.roll_damage(target.fighter, rng)
	if asleep:
		damage *= 2
		(target as Player).wake("You wake with a start!")
	var colour: Color = MessageColours.HURT if target is Player else MessageColours.HIT
	world.post_message("%s %s %s for %d." % [_cap(attacker_name), actor.attack_verb(), target_name, damage], colour)
	target.fighter.take_damage(damage)
	return true


static func _cap(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)
