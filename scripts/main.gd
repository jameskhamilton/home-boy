extends Node2D
## One floor underground: builds it, places the sloth (on the ladder home), snakes and
## a furniture crate, and keeps the view in step with each turn.
## E on the ladder = climb home (bank XP + furniture). E on the stairs = go deeper.

## Settings for the dungeon generator (edit the .tres to tune floors).
@export var dungeon_config: DungeonConfig
## Non-zero replays that exact floor; 0 = a new random seed each floor.
@export var fixed_seed: int = 0
## Use the hand-made M3 test floor instead of generating one.
@export var use_test_floor: bool = false
## Monster types that can appear (picked at random).
@export var monster_types: Array[MonsterDef] = []
## Scene used for every enemy.
@export var enemy_scene: PackedScene

const HOME_SCENE: String = "res://scenes/home.tscn"

@onready var _game_map: GameMap = $GameMap
@onready var _enemies_root: Node2D = $Enemies
@onready var _player: Player = $Player
@onready var _turns: TurnManager = $TurnManager
@onready var _hud: Hud = $HUD
@onready var _combat: CombatManager = $CombatManager
@onready var _combat_box: CombatBox = $CombatBox

var map: MapData
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pickups: Array[Pickup] = []
var _awaiting_home: bool = false # dead: waiting for Space to be carried home


func _ready() -> void:
	# Background outside the map = palette 'k'. Also in Project Settings; set here so it can't drift.
	RenderingServer.set_default_clear_color(FogOverlay.UNEXPLORED)
	_player.moved.connect(_on_player_moved)
	_player.stillness_changed.connect(_on_stillness_changed)
	_player.fighter.hp_changed.connect(_on_player_hp_changed)
	_turns.turn_ended.connect(_on_turn_ended)
	_turns.message.connect(_hud.add_message)
	_turns.player_died.connect(_on_player_died)
	_turns.cell_dug.connect(_on_cell_dug)
	_combat.world = _turns
	_combat.box = _combat_box
	_turns.combat = _combat
	GameState.changed.connect(_refresh_hud)
	if not GameState.trip_active:
		GameState.start_trip() # e.g. running this scene directly with F6
	new_floor(fixed_seed if fixed_seed != 0 else GameState.rng.randi())
	_turns.post_message("You climb down into the dark. Depth %d." % GameState.depth, MessageColours.INFO)
	_turns.post_message("Find furniture, then climb the ladder home (E).", MessageColours.MISS)
	_announce_new_creature()


## Dead: catch Space/Enter before anything else can (Space is also the "wait" key,
## which the sloth's input would otherwise swallow).
func _input(event: InputEvent) -> void:
	if not _awaiting_home:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_awaiting_home = false
		GameState.lose_trip()
		get_tree().change_scene_to_file(HOME_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if _awaiting_home:
		return
	if event.is_action_pressed("debug_new_floor") and not _turns.busy:
		new_floor(GameState.rng.randi()) # debug: reroll this floor
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_interact()


## Build a floor from the given seed at the current depth, then enter it.
func new_floor(seed_value: int) -> void:
	rng.seed = seed_value
	if use_test_floor:
		map = MapData.from_text(HandmadeMaps.TEST_FLOOR)
	else:
		map = DungeonGenerator.generate(dungeon_config, rng)
	enter_map(map)
	_spawn_enemies(GameState.depth - 1)
	_spawn_furniture()
	_spawn_items()
	_hud.set_seed(seed_value)
	_refresh_hud()
	print("Depth %d: %dx%d, %d rooms, %d enemies, seed %d" % [
		GameState.depth, map.width, map.height, map.rooms.size(), _turns.enemies.size(), seed_value])


## Draw a map and put the player on it (no enemies yet).
func enter_map(new_map: MapData) -> void:
	map = new_map
	for enemy in _turns.enemies:
		enemy.queue_free()
	for pickup in _pickups:
		pickup.queue_free()
	_pickups.clear()
	_turns.setup(_player, Pathfinder.new(map), rng)
	_game_map.draw_map(map)
	_player.map = map
	_player.world = _turns
	_player.apply_loadout()
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


## Place enemies one group per room, away from the player's start room and out of sight.
## Only creatures whose min_depth has been reached can appear; deeper floors get `extra`
## more groups. Most come alone; some (rats) come in packs. They start dormant.
func _spawn_enemies(extra: int = 0) -> void:
	var eligible: Array[MonsterDef] = []
	for def in monster_types:
		if def.min_depth <= GameState.depth:
			eligible.append(def)
	if eligible.is_empty() or map.rooms.is_empty():
		return
	var candidates: Array[Rect2i] = _shuffled_rooms_except_start()
	var groups: int = rng.randi_range(dungeon_config.enemy_count_min, dungeon_config.enemy_count_max) + extra
	groups = mini(groups, candidates.size())
	for i in groups:
		var room: Rect2i = candidates[i]
		var def: MonsterDef = eligible[rng.randi_range(0, eligible.size() - 1)]
		for n in rng.randi_range(def.pack_min, def.pack_max):
			var cell: Vector2i = _free_cell_in(room)
			if cell.x < 0:
				break
			var enemy: Enemy = spawn_enemy(def, cell)
			enemy.ai.home_room = room


## A few small items per floor: healing fruit, lucky pebbles, glow moss.
func _spawn_items() -> void:
	var rooms: Array[Rect2i] = _shuffled_rooms_except_start()
	for i in mini(rng.randi_range(1, 3), rooms.size()):
		var cell: Vector2i = _free_cell_in(rooms[i])
		if cell.x < 0:
			continue
		var item: ItemDef = Catalog.ITEMS[rng.randi_range(0, Catalog.ITEMS.size() - 1)]
		_add_pickup(Pickup.new(null, item, cell))


## One furniture crate per floor (if there's anything left to find at this depth).
func _spawn_furniture() -> void:
	var furniture: FurnitureDef = GameState.pick_furniture_for_depth(rng)
	if furniture == null:
		return
	for room in _shuffled_rooms_except_start():
		var cell: Vector2i = _free_cell_in(room)
		if cell.x >= 0:
			_add_pickup(Pickup.new(furniture, null, cell))
			return


func _add_pickup(pickup: Pickup) -> void:
	_enemies_root.add_child(pickup)
	_enemies_root.move_child(pickup, 0) # draw under creatures
	_pickups.append(pickup)
	pickup.refresh_visibility(map)


func _shuffled_rooms_except_start() -> Array[Rect2i]:
	var rooms: Array[Rect2i] = []
	for room in map.rooms:
		if not room.has_point(map.player_start):
			rooms.append(room)
	# Shuffle with the seeded RNG (Array.shuffle() would use the global RNG).
	for i in range(rooms.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Rect2i = rooms[i]
		rooms[i] = rooms[j]
		rooms[j] = tmp
	return rooms


## A random floor cell in the room that's out of sight, empty and not the stairs; (-1,-1) if none.
func _free_cell_in(room: Rect2i) -> Vector2i:
	for attempt in 20:
		var cell := Vector2i(
			rng.randi_range(room.position.x, room.end.x - 1),
			rng.randi_range(room.position.y, room.end.y - 1))
		if map.get_tile(cell) != MapData.Tile.FLOOR or map.is_visible(cell) or _turns.actor_at(cell) != null:
			continue
		var taken: bool = false
		for p in _pickups:
			if p.grid_pos == cell:
				taken = true
		if not taken:
			return cell
	return Vector2i(-1, -1)


func _interact() -> void:
	if _turns.busy or _player.is_dead():
		return
	var cell: Vector2i = _player.grid_pos
	if cell == map.ladder_pos:
		GameState.finish_trip_home()
		get_tree().change_scene_to_file(HOME_SCENE)
	elif cell == map.stairs_pos:
		GameState.descend()
		new_floor(GameState.rng.randi())
		_turns.post_message("You go deeper. Depth %d." % GameState.depth, MessageColours.INFO)
		_announce_new_creature()
	else:
		_turns.post_message("Nothing to use here. (E works on the ladder and stairs.)", MessageColours.MISS)


## Every time the player lands on a cell: update sight, pick up crates, hint at ladder/stairs.
func _on_player_moved(cell: Vector2i) -> void:
	map.update_fov(cell, _player.sight_radius)
	_game_map.refresh_fog()
	for pickup in _pickups.duplicate():
		if pickup.grid_pos == cell and _take(pickup):
			_pickups.erase(pickup)
			pickup.queue_free()
		else:
			pickup.refresh_visibility(map)
	if cell == map.ladder_pos and _turns.turn > 0:
		_turns.post_message("The ladder home. Press E to climb up and bank what you carry.", MessageColours.MISS)
	elif cell == map.stairs_pos:
		_turns.post_message("Stairs down. Press E to go deeper.", MessageColours.MISS)


## Walked onto a pickup: carry furniture, or use an item. Returns false to leave it there.
func _take(pickup: Pickup) -> bool:
	if pickup.furniture != null:
		GameState.carry(pickup.furniture)
		_turns.post_message("You found a %s! Carry it home. (%s)" % [
			pickup.furniture.display_name.to_lower(), pickup.furniture.description], MessageColours.GOOD)
		return true
	var item: ItemDef = pickup.item
	match item.effect:
		ItemDef.Effect.HEAL:
			if _player.fighter.hp >= _player.fighter.max_hp:
				_turns.post_message("A healing fruit. You're not hurt, so you leave it for later.", MessageColours.MISS)
				return false
			var healed: int = _player.fighter.heal(GameState.fruit_heal())
			_turns.post_message("You eat a healing fruit. +%d HP" % healed, MessageColours.HIT)
		ItemDef.Effect.LUCKY_DIE:
			GameState.lucky_dice += item.amount
			_turns.post_message("A lucky pebble! +%d die in your next fight." % item.amount, MessageColours.GOOD)
			_refresh_status()
		ItemDef.Effect.XP:
			GameState.add_xp(item.amount)
			_turns.post_message("Glowing moss. +%d XP" % item.amount, MessageColours.GOOD)
	return true


## A mole dug through a wall: redraw it, let paths through, and refresh sight.
func _on_cell_dug(cell: Vector2i) -> void:
	_game_map.redraw_cell(map, cell)
	_turns.pathfinder.open_cell(cell)
	map.update_fov(_player.grid_pos, _player.sight_radius)
	_game_map.refresh_fog()


## After everyone has acted, show only the enemies the player can see.
func _on_turn_ended(_turn: int) -> void:
	for enemy in _turns.enemies:
		enemy.refresh_visibility()


func _on_player_hp_changed(hp: int, _max_hp: int) -> void:
	GameState.trip_hp = hp
	_hud.set_hp(hp, _player.fighter.max_hp)


func _on_stillness_changed(_still_turns: int, _camouflaged: bool) -> void:
	_refresh_status()


## Status line: stillness progress.
func _refresh_status() -> void:
	var parts: Array[String] = []
	if _player.is_camouflaged():
		parts.append("Camouflaged")
	elif _player.still_turns > 0:
		parts.append("Still %d/%d" % [_player.still_turns, _player.turns_to_camouflage])
	if GameState.lucky_dice > 0:
		parts.append("Lucky pebble: +%d die next fight" % GameState.lucky_dice)
	_hud.set_status("  ".join(parts))


func _refresh_hud() -> void:
	_hud.set_xp(GameState.carried_xp, GameState.banked_xp)
	_hud.set_depth(GameState.depth)
	var names: Array[String] = []
	for f in GameState.carried_furniture:
		names.append(f.display_name)
	_hud.set_carrying(", ".join(names))


func _on_player_died() -> void:
	_player.modulate = Color(1, 1, 1, 0.35)
	_awaiting_home = true
	var lost: String = "%d XP" % GameState.carried_xp
	if not GameState.carried_furniture.is_empty():
		lost += " and your furniture"
	_hud.show_game_over(true, "You collapse...\nA macaw carries you home.\nYou lose %s.\n\nPress Space" % lost)


## A hint when a new kind of creature starts appearing at this depth.
func _announce_new_creature() -> void:
	for def in monster_types:
		if def.min_depth == GameState.depth and def.min_depth > 1:
			_turns.post_message("Something new lives down here: the %s." % def.display_name, MessageColours.HURT)
