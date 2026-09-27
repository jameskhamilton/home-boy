class_name EnemyAI
extends Node
## Decides what an enemy does each turn:
## - DORMANT: lurks in its home room until the player sees it for the first time.
## - WANDER: walk between random rooms.
## - HUNT: chase the player while it can see them.
## - SEARCH: go (carefully, at `search_pace`) to where it last saw the player, poke around, then give up.
## - REST: tired after chasing for `chase_stamina` turns; stands still for `rest_turns`.
##   It keeps watching while resting: if it can still see you when it wakes, the chase
##   resumes; if you got out of sight, it searches (and camouflage can fool it).
## Camouflage rule: a camouflaged player can't be *noticed*; an enemy that is already
## hunting keeps tracking them only while they stay in its sight.

enum State { WANDER, HUNT, SEARCH, REST, DORMANT }

const _DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

var state: State = State.DORMANT
## The room it spawned in; it stays here while dormant.
var home_room: Rect2i = Rect2i()

var _last_seen: Vector2i = Vector2i.ZERO
var _search_left: int = 0
var _wander_target: Vector2i = Vector2i.ZERO
var _has_wander_target: bool = false
var _chase_turns: int = 0 # consecutive turns spent hunting
var _rest_left: int = 0
var _search_tick: int = 0 # counts search turns, for moving at search pace

@onready var _enemy: Enemy = get_parent()


## Choose this turn's action.
func take_turn(player: Player, pathfinder: Pathfinder, rng: RandomNumberGenerator) -> Action:
	if state == State.DORMANT:
		if not _enemy.map.is_visible(_enemy.grid_pos):
			_enemy.show_state(state)
			return _lurk(player, rng)
		state = State.WANDER # the player has spotted it: from now on it's active
	if state == State.REST:
		# Resting, but still watching: it keeps tracking you while you're in sight.
		if can_see(player):
			_last_seen = player.grid_pos
		_rest_left -= 1
		if _rest_left > 0:
			_enemy.show_state(state)
			return WaitAction.new(_enemy)
		# Rested. Still in sight: the chase resumes (camouflage can't fool a watcher).
		# Out of sight: it searches where it last saw you (camouflage works now).
		_chase_turns = 0
		if can_see(player):
			state = State.HUNT
		else:
			state = State.SEARCH
			_search_left = _enemy.def.search_turns if _enemy.def != null else 5
	var sees: bool = can_see(player)
	var noticed: bool = sees and (state == State.HUNT or not player.is_camouflaged())
	if noticed:
		state = State.HUNT
		_last_seen = player.grid_pos
	elif state == State.HUNT:
		_chase_turns = 0
		state = State.SEARCH
		_search_left = _enemy.def.search_turns if _enemy.def != null else 5

	var action: Action
	match state:
		State.HUNT:
			_chase_turns += 1
			var stamina: int = _enemy.def.chase_stamina if _enemy.def != null else 0
			if stamina > 0 and _chase_turns > stamina:
				state = State.REST
				_rest_left = _enemy.def.rest_turns
				_chase_turns = 0
				action = WaitAction.new(_enemy)
			else:
				action = _step_toward(player.grid_pos, player, pathfinder)
		State.SEARCH:
			action = _search(player, pathfinder, rng)
		_:
			action = _wander(player, pathfinder, rng)
	_enemy.show_state(state)
	return action


## True if the enemy has line of sight to the player within its sight radius.
## FOV is symmetric, so "the player can see this cell" = "this cell can see the player".
func can_see(player: Player) -> bool:
	var offset: Vector2i = player.grid_pos - _enemy.grid_pos
	var r: int = _enemy.sight_radius
	if offset.x * offset.x + offset.y * offset.y > r * r + r:
		return false
	return _enemy.map.is_visible(_enemy.grid_pos)


func _search(player: Player, pathfinder: Pathfinder, rng: RandomNumberGenerator) -> Action:
	# Searching is careful: only move every `search_pace` turns.
	_search_tick += 1
	var pace: int = _enemy.def.search_pace if _enemy.def != null else 1
	if pace > 1 and _search_tick % pace != 0:
		return WaitAction.new(_enemy)
	if _enemy.grid_pos != _last_seen:
		var dir: Vector2i = pathfinder.next_step(_enemy.grid_pos, _last_seen)
		if dir != Vector2i.ZERO:
			return _step_or_wait(dir, player)
		_last_seen = _enemy.grid_pos # can't get there: search from here
	_search_left -= 1
	if _search_left <= 0:
		state = State.WANDER
		_has_wander_target = false
	return _random_step(player, rng)


func _wander(player: Player, pathfinder: Pathfinder, rng: RandomNumberGenerator) -> Action:
	var rooms: Array[Rect2i] = _enemy.map.rooms
	if rooms.is_empty():
		return _random_step(player, rng)
	if not _has_wander_target or _enemy.grid_pos == _wander_target:
		var room: Rect2i = rooms[rng.randi_range(0, rooms.size() - 1)]
		_wander_target = Vector2i(
			rng.randi_range(room.position.x, room.end.x - 1),
			rng.randi_range(room.position.y, room.end.y - 1))
		_has_wander_target = true
	var dir: Vector2i = pathfinder.next_step(_enemy.grid_pos, _wander_target)
	if dir == Vector2i.ZERO:
		_has_wander_target = false
		return WaitAction.new(_enemy)
	return _step_or_wait(dir, player)


func _step_toward(target: Vector2i, player: Player, pathfinder: Pathfinder) -> Action:
	var dir: Vector2i = pathfinder.next_step(_enemy.grid_pos, target)
	if dir == Vector2i.ZERO:
		return WaitAction.new(_enemy)
	return _step_or_wait(dir, player)


## Step if the way is clear. Bumping into the player gives them away (even camouflaged)
## and, while hunting, means attacking.
func _step_or_wait(dir: Vector2i, player: Player) -> Action:
	if _enemy.grid_pos + dir == player.grid_pos:
		if state != State.HUNT:
			state = State.HUNT
			_last_seen = player.grid_pos
			return WaitAction.new(_enemy) # it has just found you; it strikes next turn
		if _enemy.can_attack(dir):
			return MeleeAction.new(_enemy, dir)
		return WaitAction.new(_enemy)
	if _enemy.can_step(dir):
		return MoveAction.new(_enemy, dir)
	return WaitAction.new(_enemy)


func _random_step(player: Player, rng: RandomNumberGenerator) -> Action:
	var options: Array[Vector2i] = []
	for dir in _DIRECTIONS:
		if _enemy.can_step(dir) and _enemy.grid_pos + dir != player.grid_pos:
			options.append(dir)
	if options.is_empty():
		return WaitAction.new(_enemy)
	return MoveAction.new(_enemy, options[rng.randi_range(0, options.size() - 1)])


## Dormant behaviour: now and then shuffle one step, staying inside the home room.
func _lurk(player: Player, rng: RandomNumberGenerator) -> Action:
	if rng.randi_range(0, 2) != 0:
		return WaitAction.new(_enemy)
	var options: Array[Vector2i] = []
	for dir in _DIRECTIONS:
		var target: Vector2i = _enemy.grid_pos + dir
		if (home_room.size == Vector2i.ZERO or home_room.has_point(target)) \
				and _enemy.can_step(dir) and target != player.grid_pos:
			options.append(dir)
	if options.is_empty():
		return WaitAction.new(_enemy)
	return MoveAction.new(_enemy, options[rng.randi_range(0, options.size() - 1)])
