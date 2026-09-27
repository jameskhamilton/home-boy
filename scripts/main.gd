extends Node2D
## Wires the game together: builds a floor, places the player and enemies,
## and keeps the view (fog, enemy visibility, HUD) in step with each turn.

## Settings for the dungeon generator (edit the .tres to tune floors).
@export var dungeon_config: DungeonConfig
## Non-zero replays that exact floor; 0 = a new random seed each run.
@export var fixed_seed: int = 0
## Use the hand-made M3 test floor instead of generating one.
@export var use_test_floor: bool = false
## Monster types that can appear (picked at random).
@export var monster_types: Array[MonsterDef] = []
## Scene used for every enemy.
@export var enemy_scene: PackedScene

@onready var _game_map: GameMap = $GameMap
@onready var _enemies_root: Node2D = $Enemies
@onready var _player: Player = $Player
@onready var _turns: TurnManager = $TurnManager
@onready var _hud: Hud = $HUD
@onready var _combat: CombatManager = $CombatManager
@onready var _combat_box: CombatBox = $CombatBox

var map: MapData
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	# Background outside the map = palette 'k'. Also in Project Settings; set here so it can't drift.
	RenderingServer.set_default_clear_color(FogOverlay.UNEXPLORED)
	_player.moved.connect(_on_player_moved)
	_player.stillness_changed.connect(_on_stillness_changed)
	_player.napping_changed.connect(func(_n: bool) -> void: _refresh_status())
	_player.xp_changed.connect(_hud.set_xp)
	_player.fighter.hp_changed.connect(_hud.set_hp)
	_turns.turn_ended.connect(_on_turn_ended)
	_turns.message.connect(_hud.add_message)
	_turns.player_died.connect(_on_player_died)
	_combat.world = _turns
	_combat.box = _combat_box
	_turns.combat = _combat
	var seed_value: int = fixed_seed if fixed_seed != 0 else randi()
	new_run(seed_value)


func _unhandled_input(event: InputEvent) -> void:
	# R: start a fresh run (also how you continue after dying).
	if event.is_action_pressed("debug_new_floor"):
		new_run(randi())
		get_viewport().set_input_as_handled()


## Permadeath means every run starts fresh: full HP, no XP, new floor.
func new_run(seed_value: int) -> void:
	_hud.show_game_over(false)
	_hud.clear_messages()
	_player.reset_for_new_run()
	_player.modulate = Color.WHITE
	new_floor(seed_value)
	_turns.post_message("You wake in the dark, far from home.", MessageColours.INFO)


## Build a floor from the given seed, then enter it with enemies.
func new_floor(seed_value: int) -> void:
	rng.seed = seed_value
	if use_test_floor:
		map = MapData.from_text(HandmadeMaps.TEST_FLOOR)
	else:
		map = DungeonGenerator.generate(dungeon_config, rng)
	enter_map(map)
	_spawn_enemies()
	_hud.set_seed(seed_value)
	print("Floor %dx%d, %d rooms, %d enemies, seed %d" % [
		map.width, map.height, map.rooms.size(), _turns.enemies.size(), seed_value])


## Draw a map and put the player on it (no enemies yet).
func enter_map(new_map: MapData) -> void:
	map = new_map
	for enemy in _turns.enemies:
		enemy.queue_free()
	_turns.setup(_player, Pathfinder.new(map), rng)
	_game_map.draw_map(map)
	_player.map = map
	_player.world = _turns
	_player.reset_stillness()
	_player.place_at(map.player_start)
	_player.set_camera_limits(Vector2i(map.width, map.height) * GameMap.TILE_SIZE)


## Create one enemy of the given type on a cell.
func spawn_enemy(def: MonsterDef, cell: Vector2i) -> Enemy:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.def = def
	enemy.map = map
	enemy.world = _turns
	enemy.grid_pos = cell
	_enemies_root.add_child(enemy)
	_turns.enemies.append(enemy)
	enemy.refresh_visibility()
	return enemy


## Place enemies one per room (never two in the same room), away from the player's
## start room and out of sight. They start dormant until the player spots them.
func _spawn_enemies() -> void:
	if monster_types.is_empty() or map.rooms.is_empty():
		return
	var candidates: Array[Rect2i] = []
	for room in map.rooms:
		if not room.has_point(map.player_start):
			candidates.append(room)
	# Shuffle with the seeded RNG (Array.shuffle() would use the global RNG).
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Rect2i = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var count: int = rng.randi_range(dungeon_config.enemy_count_min, dungeon_config.enemy_count_max)
	count = mini(count, candidates.size())
	for i in count:
		var room: Rect2i = candidates[i]
		for attempt in 20:
			var cell := Vector2i(
				rng.randi_range(room.position.x, room.end.x - 1),
				rng.randi_range(room.position.y, room.end.y - 1))
			if map.is_visible(cell) or _turns.actor_at(cell) != null:
				continue
			var def: MonsterDef = monster_types[rng.randi_range(0, monster_types.size() - 1)]
			var enemy: Enemy = spawn_enemy(def, cell)
			enemy.ai.home_room = room
			break


## Every time the player lands on a cell, update what they can see.
func _on_player_moved(cell: Vector2i) -> void:
	map.update_fov(cell, _player.sight_radius)
	_game_map.refresh_fog()


## After everyone has acted, show only the enemies the player can see.
func _on_turn_ended(_turn: int) -> void:
	for enemy in _turns.enemies:
		enemy.refresh_visibility()


func _on_stillness_changed(_still_turns: int, _camouflaged: bool) -> void:
	_refresh_status()


## Status line: napping and/or stillness progress.
func _refresh_status() -> void:
	var parts: Array[String] = []
	if _player.napping:
		parts.append("Napping")
	if _player.is_camouflaged():
		parts.append("Camouflaged")
	elif _player.still_turns > 0:
		parts.append("Still %d/%d" % [_player.still_turns, _player.turns_to_camouflage])
	_hud.set_status("  ".join(parts))


func _on_player_died() -> void:
	_player.modulate = Color(1, 1, 1, 0.35)
	_hud.show_game_over(true)








