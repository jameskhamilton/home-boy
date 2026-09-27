# Home Boy — Dev log

Newest first. 3–5 lines per session: done / learned / next.

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
