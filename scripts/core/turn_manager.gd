class_name TurnManager
extends Node
## Runs the turn order: the player acts, then every enemy acts in turn.
## When an action starts a fight, the turn pauses while the combat box plays it out.
## Also answers "who is standing on this cell?" for blocking.

## Emitted after everyone has acted.
signal turn_ended(turn: int)
## A line for the message log.
signal message(text: String, colour: Color)
## Emitted when the player's HP reaches 0.
signal player_died
## A digger (mole) turned a wall cell into floor.
signal cell_dug(cell: Vector2i)

var player: Player
var enemies: Array[Enemy] = []
var pathfinder: Pathfinder
## Seeded RNG shared by the AI and dice, so a seed replays the run.
var rng: RandomNumberGenerator
## Plays fights out (set by Main).
var combat: CombatManager
var turn: int = 0
## True while a turn (or a fight inside it) is being played. Input is ignored meanwhile.
var busy: bool = false

var _pending: Array[CombatRequest] = []


## Reset for a new floor.
func setup(p_player: Player, p_pathfinder: Pathfinder, p_rng: RandomNumberGenerator) -> void:
	player = p_player
	pathfinder = p_pathfinder
	rng = p_rng
	enemies.clear()
	_pending.clear()
	turn = 0
	busy = false


## The actor on a cell, or null.
func actor_at(cell: Vector2i) -> Actor:
	if player != null and player.grid_pos == cell:
		return player
	for enemy in enemies:
		if enemy.grid_pos == cell:
			return enemy
	return null


## Queue a fight; it is played as soon as the current action finishes.
func request_combat(request: CombatRequest) -> void:
	_pending.append(request)


## Perform the player's action; if it used a turn, let every enemy act.
## This is a coroutine: fights inside the turn are awaited.
func play_turn(action: Action) -> void:
	if busy or player.is_dead():
		return
	busy = true
	if not action.perform():
		busy = false
		return # e.g. walked into a wall: no time passes
	player.after_action(action)
	await _run_pending_fights()
	for enemy in enemies.duplicate(): # copy: enemies can die mid-loop
		if player.is_dead():
			break
		if not is_instance_valid(enemy) or not enemies.has(enemy):
			continue
		# Fast creatures (bats) get several steps per turn.
		for step in enemy.def.moves_per_turn:
			if player.is_dead() or not is_instance_valid(enemy) or not enemies.has(enemy):
				break
			var enemy_action: Action = enemy.ai.take_turn(player, pathfinder, rng)
			if enemy_action != null:
				enemy_action.perform()
			await _run_pending_fights()
			if not (enemy_action is MoveAction):
				break
	turn += 1
	busy = false
	turn_ended.emit(turn)
	if player.is_dead():
		player_died.emit()


func _run_pending_fights() -> void:
	while not _pending.is_empty():
		var request: CombatRequest = _pending.pop_front()
		if not is_instance_valid(request.enemy) or not enemies.has(request.enemy) or player.is_dead():
			continue
		await combat.fight(request)


## Add a line to the message log.
func post_message(text: String, colour: Color = MessageColours.INFO) -> void:
	message.emit(text, colour)


## Remove a defeated enemy (no XP: XP comes from leaves rolled in combat).
func enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
	post_message("%s is defeated." % [MeleeAction._cap(enemy.display_name())], MessageColours.GOOD)
	enemy.queue_free()
