class_name DungeonGenerator
extends RefCounted
## Builds a random floor:
## 1. Split the map into a grid of zones; most zones get one randomly sized room.
## 2. Join rooms nearest-first until all are connected (a minimum spanning tree).
## 3. Add a few extra corridors between neighbouring rooms so there are loops.
## Corridors pick the route (L- or Z-shaped) that avoids running alongside other corridors.
## Same config + same RNG seed = same floor, every time.


## Generate a new MapData from the config, using the (already seeded) RNG.
static func generate(config: DungeonConfig, rng: RandomNumberGenerator) -> MapData:
	var map: MapData = MapData.new(config.map_size.x, config.map_size.y)
	var rooms: Array[Rect2i] = []
	var zones: Array[Vector2i] = [] # zone (column, row) of each room, same order as rooms

	_place_rooms(map, config, rng, rooms, zones, config.room_chance)
	if rooms.size() < 2:
		# Unlucky roll: fill every zone so there is always somewhere to go.
		rooms.clear()
		zones.clear()
		_place_rooms(map, config, rng, rooms, zones, 1.0)
	if rooms.is_empty():
		push_error("DungeonGenerator: no rooms placed - check DungeonConfig.")
		return map
	var router: CorridorRouter = CorridorRouter.new(map, rng)
	for room in rooms:
		_carve_room(map, room)
		router.mark_room(room)
	_connect_nearest_first(rooms, router)
	_add_loops(config, rng, rooms, zones, router)

	map.rooms = rooms
	map.player_start = rooms[rng.randi_range(0, rooms.size() - 1)].get_center()
	# You arrive by the ladder home; the stairs down are in the farthest room (by walking distance).
	map.ladder_pos = map.player_start
	map.set_tile(map.ladder_pos, MapData.Tile.LADDER_UP)
	map.stairs_pos = _farthest_room_center(map, rooms)
	map.set_tile(map.stairs_pos, MapData.Tile.STAIRS_DOWN)
	return map


## Centre of the room furthest (in steps) from the player's start.
static func _farthest_room_center(map: MapData, rooms: Array[Rect2i]) -> Vector2i:
	var dist: Dictionary[Vector2i, int] = {map.player_start: 0}
	var queue: Array[Vector2i] = [map.player_start]
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if map.is_walkable(n) and not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	var best: Vector2i = map.player_start
	var best_d: int = -1
	for room in rooms:
		var centre: Vector2i = room.get_center()
		if centre != map.player_start and dist.get(centre, -1) > best_d:
			best_d = dist[centre]
			best = centre
	return best


## One room per zone (skipping some at random), kept inside the zone with a wall margin.
static func _place_rooms(map: MapData, config: DungeonConfig, rng: RandomNumberGenerator,
		rooms: Array[Rect2i], zones: Array[Vector2i], chance: float) -> void:
	@warning_ignore("integer_division")
	var zone_w: int = map.width / config.zone_columns
	@warning_ignore("integer_division")
	var zone_h: int = map.height / config.zone_rows
	for row in config.zone_rows:
		for col in config.zone_columns:
			if rng.randf() > chance:
				continue
			# Leave at least 1 wall on each side inside the zone, so rooms never touch.
			var max_w: int = mini(config.room_size_max, zone_w - 2)
			var max_h: int = mini(config.room_size_max, zone_h - 2)
			var w: int = rng.randi_range(mini(config.room_size_min, max_w), max_w)
			var h: int = rng.randi_range(mini(config.room_size_min, max_h), max_h)
			var zone_x: int = col * zone_w
			var zone_y: int = row * zone_h
			var x: int = rng.randi_range(zone_x + 1, zone_x + zone_w - w - 1)
			var y: int = rng.randi_range(zone_y + 1, zone_y + zone_h - h - 1)
			rooms.append(Rect2i(x, y, w, h))
			zones.append(Vector2i(col, row))


## Prim's algorithm: repeatedly link the closest unconnected room to the connected set.
static func _connect_nearest_first(rooms: Array[Rect2i], router: CorridorRouter) -> void:
	var connected: Array[int] = [0]
	var remaining: Array[int] = []
	for i in range(1, rooms.size()):
		remaining.append(i)
	while not remaining.is_empty():
		var best_from: int = -1
		var best_to: int = -1
		var best_dist: int = 1 << 30
		for a in connected:
			for b in remaining:
				var d: int = _distance(rooms[a].get_center(), rooms[b].get_center())
				if d < best_dist:
					best_dist = d
					best_from = a
					best_to = b
		router.connect_points(rooms[best_from].get_center(), rooms[best_to].get_center(), true)
		connected.append(best_to)
		remaining.erase(best_to)


## Sometimes add a corridor between rooms in side-by-side zones, making loops.
static func _add_loops(config: DungeonConfig, rng: RandomNumberGenerator,
		rooms: Array[Rect2i], zones: Array[Vector2i], router: CorridorRouter) -> void:
	for a in rooms.size():
		for b in range(a + 1, rooms.size()):
			var gap: Vector2i = (zones[a] - zones[b]).abs()
			if gap.x + gap.y == 1 and rng.randf() < config.extra_loop_chance:
				# Loops are optional: only keep one if it has a clean route.
				router.connect_points(rooms[a].get_center(), rooms[b].get_center(), false)


## Grid (Manhattan) distance between two cells.
static func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _carve_room(map: MapData, room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			map.set_tile(Vector2i(x, y), MapData.Tile.FLOOR)

