class_name TurnManager
extends Node
## Runs the turn order: the player acts, then every enemy acts in turn.
## Also answers "who is standing on this cell?" for blocking.

## Emitted after everyone has acted.
signal turn_ended(turn: int)

var player: Player
var enemies: Array[Enemy] = []
var pathfinder: Pathfinder
## Seeded RNG shared by the AI, so a seed replays enemy behaviour too.
var rng: RandomNumberGenerator
var turn: int = 0


## Reset for a new floor.
func setup(p_player: Player, p_pathfinder: Pathfinder, p_rng: RandomNumberGenerator) -> void:
	player = p_player
	pathfinder = p_pathfinder
	rng = p_rng
	enemies.clear()
	turn = 0


## The actor on a cell, or null.
func actor_at(cell: Vector2i) -> Actor:
	if player != null and player.grid_pos == cell:
		return player
	for enemy in enemies:
		if enemy.grid_pos == cell:
			return enemy
	return null


## Perform the player's action; if it used a turn, let every enemy act.
func play_turn(action: Action) -> void:
	if not action.perform():
		return # e.g. walked into a wall: no time passes
	player.after_action(action)
	for enemy in enemies:
		var enemy_action: Action = enemy.ai.take_turn(player, pathfinder, rng)
		if enemy_action != null:
			enemy_action.perform()
	turn += 1
	turn_ended.emit(turn)
