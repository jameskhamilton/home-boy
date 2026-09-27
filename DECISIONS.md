# Home Boy — Decisions

One line each: what was decided and why. Newest at the bottom.

- 2026-09-27 — Godot 4.7.2, GL Compatibility renderer: 2D pixel art needs nothing more, runs on modest GPUs.
- 2026-09-27 — 16×16 tiles, 480×270 viewport, integer scaling, Nearest filter: crisp pixels, 30×16 tiles on screen.
- 2026-09-27 — Player is a Node2D with a logical `grid_pos: Vector2i`; `position` is derived. No physics for movement.
- 2026-09-27 — Sprite2D `centered = false` so a node's position is its tile's top-left corner.
- 2026-09-27 — Input via named actions (move_up/down/left/right on arrows + WASD) in `_unhandled_input`, key-repeat on.
- 2026-09-27 — Movement lives in `Player.move(dir)` so it can later become a MoveAction (M6).
- 2026-09-27 — (James) Floors are larger than the screen with a following camera (classic scrolling), not single-screen.
- 2026-09-27 — (James) Claude commits at each milestone; James pushes.
- 2026-09-27 — `MapData` (RefCounted, PackedByteArray grid, enum Tile) is the map's source of truth; `GameMap` + `TileMapLayer` only draw it.
- 2026-09-27 — Out-of-bounds cells count as WALL, so no edge checks needed elsewhere.
- 2026-09-27 — Hand-made test floor is a text grid ('#', '.', '@') in `HandmadeMaps.TEST_FLOOR`; the M4 generator will output the same MapData.
- 2026-09-27 — Single `TILE_SIZE` const lives in `GameMap`; Player uses it.
- 2026-09-27 — Camera2D is a child of Player (offset 8,8 to centre on the sprite), limits clamp to the map; no smoothing yet (keeps pixels crisp).
- 2026-09-27 — (James) Floors are 120×72 (double M3's size each way); simple random rooms first.
- 2026-09-27 — DungeonGenerator v2 (after James saw clustering/striping): map split into 5×4 zones, ≤1 room per zone (80% chance), rooms joined nearest-first (Prim MST) + 15% extra loops between neighbouring zones. Start = random room.
- 2026-09-27 — Tuning lives in `DungeonConfig` Resource (`data/dungeon/default_dungeon.tres`): zones 5×4, room_chance 0.8, rooms 5–13 tiles, extra_loop_chance 0.15.
- 2026-09-27 — Seed: random each run unless Main.fixed_seed ≠ 0; shown top-left in a HUD label. R = new floor (debug action `debug_new_floor`).
- 2026-09-27 — Hand-made test floor kept behind Main.use_test_floor.
- 2026-09-27 — (James) Floors shrunk to 80×48 to feel less sparse, keeping the same 5×4 zones (11–20 rooms).
- 2026-09-27 — (James) No parallel corridors: new `CorridorRouter` tries every L/Z route and picks the one that doesn't run 1–2 tiles beside another corridor (crossings allowed); optional loop corridors are dropped if no clean route. ~45 ms per floor.
