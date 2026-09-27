# Home Boy — Roadmap

Godot **4.7.2** (standard, GDScript) · Compatibility renderer · 2D turn-based grid roguelike.
Player character: a sloth.

## Current milestone
**Design session** (goal, progression, hook) → then **5. Field of view**

## Milestones
- [x] 1. Setup: project, Git, pixel-art settings, docs, sprites imported
- [x] 2. The @ moves: sloth on a grid, one tile per key press
- [x] 3. A map: hand-made floors and walls; walls block movement
- [x] 4. Procedural dungeon: rooms and corridors (random rooms, then BSP)
- [ ] 5. Field of view: shadowcasting, visible + explored tiles
- [ ] 6. Enemies and turns: turn manager, chase AI, blocking
- [ ] 7. Combat: HP, attack/defence, death, message log, HP bar
- [ ] 8. Items and inventory: healing potion, pick up/drop, inventory UI
- [ ] 9. Descending: stairs, deeper levels, difficulty scaling
- [ ] 10. Save and load
- [ ] 11. Polish: tweened movement, hit flashes, screen shake, sound

## Art spec
- Tile size: **16×16**, one size for everything
- Palette (16 colours, the only colours allowed):
  `k #1b1420` `d #3b2a22` `m #6b4e36` `l #9c7a54` `c #d9c49c`
  `f #2e2a3a` `F #3d3850` `w #5a5468` `W #7e7892`
  `g #3e7a3a` `G #7fb24a` `r #b13e53` `y #e8b04a` `b #3b5dc9` `t #f4efe2`
- Sheets: `art/tiles.png`, `art/actors.png` (later `items`, `ui`) — strict grid, no padding
- Source of truth: `art/src/<sheet>.json`; regenerate PNGs with `python tools/export_sprites.py`
- Slots are stable: a sprite's `[col, row]` never moves
- Animation frames sit in adjacent columns on the same row
- Sprite canvas: https://claude.ai/artifact/NBKw3ToJQo3fPBtrw2A7W3

### Current slots
| Sheet | Name | Atlas |
|---|---|---|
| actors | sloth_idle_0 | [0, 0] |
| actors | sloth_idle_1 | [1, 0] |
| tiles | floor_0 | [0, 0] |
| tiles | wall_0 | [1, 0] |

## Display settings
Viewport 480×270 (30×16 tiles) · window 1440×810 · stretch canvas_items, integer scale · texture filter Nearest · snap 2D transforms to pixel.
