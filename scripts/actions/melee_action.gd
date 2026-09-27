class_name MeleeAction
extends Action
## Bump into an opponent: starts a dice fight in the combat box.
## The fight itself is played out by CombatManager once this action is performed.

var direction: Vector2i


func _init(p_actor: Actor, p_direction: Vector2i) -> void:
	super(p_actor)
	direction = p_direction


func perform() -> bool:
	var world: TurnManager = actor.world
	var target: Actor = world.actor_at(actor.grid_pos + direction)
	if target == null:
		return false
	var player: Player = world.player
	var enemy: Enemy = (target if actor is Player else actor) as Enemy
	if enemy == null:
		return false
	var player_started: bool = actor is Player
	world.request_combat(CombatRequest.new(
		enemy,
		player_started and player.is_camouflaged(), # ambush: +1 die
		not player_started and player.napping))     # caught napping: free double bite
	return true


static func _cap(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)
