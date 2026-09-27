# Home Boy — Dev log

Newest first. 3–5 lines per session: done / learned / next.

## 2026-09-27 — M6: enemies, turns, stealth
- Done: Action pattern + TurnManager, Actor base, A* pathfinding, cave snakes (MonsterDef data), WANDER/HUNT/SEARCH/REST/DORMANT AI, stillness camouflage (Space = wait), state markers, one snake per room. Play-tested OK.
- Decided (James): cave snake; search then wander; camo after 3 waits, only out of sight; snakes tire (8 chase / 3 rest), dormant until first spotted.
- Learned: equal-speed chasers make escape impossible without a rule (tiring + slow search); Godot log folder now readable for debugging.
- Next: M7 — combat, HP, death, message log, XP, nap.

## 2026-09-27 — M5: field of view + 8-way movement
- Done: shadowcasting FOV (radius 8), explored memory, fog overlay; DirectionInput component with two-key diagonals, own hold-repeat, no corner-cutting, wall sliding. Play-tested OK.
- Decided (James): game design (fetch & return, XP → gear at floor end, nap mechanic, stillness = stealth); diagonals via chords; halved repeat delay; no clipping at corridor entrances.
- Learned: automated input tests by injecting InputEventActions; FOV symmetry check matters for fair stealth.
- Next: M6 — enemies, turn manager, chase AI, stillness camouflage.

## 2026-09-27 — M4: procedural dungeon
- Done: seeded DungeonGenerator (zones → rooms → nearest-first corridors + loops), CorridorRouter that avoids parallel corridors, DungeonConfig .tres for tuning, seed HUD label, R = new floor. Play-tested OK.
- Decided (James): 80×48 floors with 11–20 rooms; no clustering; no side-by-side corridors.
- Learned: iterate on feel with play-tests; verified with 200-seed checks (connectivity, stripes, ~45 ms/floor).
- Next: design session (goal of a run, levelling, hook), then M5 field of view.

## 2026-09-27 — M3: a map
- Done: MapData grid (source of truth), hand-made 60x36 test floor, TileSet from tiles.png, GameMap draws via TileMapLayer, walls block movement, camera follows the sloth within map limits. Play-tested OK.
- Decided (James): scrolling floors bigger than the screen; Claude commits per milestone, James pushes.
- Note: MCP debug output doesn't capture print(); used a temp file check. Log-folder access would fix this.
- Next: M4 — procedural dungeon (rooms + corridors, seeded RNG).

## 2026-09-27 — M2: the sloth moves
- Done: Input Map (arrows + WASD), `scenes/player.tscn` (Node2D + Sprite2D), `scripts/entities/player.gd` grid movement. Play-tested OK.
- Decided: grid_pos (Vector2i) is the truth, pixel position derived; sprite uses Centered off.
- Note: the Godot MCP can't set textures on nodes; set via .tscn text + reload_scene_from_disk.
- Next: M3 — hand-made map with floors/walls; walls block movement.

## 2026-09-27 — Setup
- Done: installed Godot 4.7.2, created project "Home Boy", pixel-art display settings, `scenes/main.tscn` runs (F5).
- Done: sloth + placeholder floor/wall sprites added under `art/`, with JSON sources and export script.
- Learned: `res://` is the project root; `.godot/` is a rebuildable import cache (kept out of Git).
- Next: first Git commit, then Milestone 2 — the sloth moves on a grid.
