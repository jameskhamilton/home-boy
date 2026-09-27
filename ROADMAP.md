# Home Boy — Roadmap

Godot **4.7.2** (standard, GDScript) · Compatibility renderer · 2D turn-based grid roguelike.
Player character: a sloth.

## Current milestone
**10. Save and load** — next

## Game design (decided 2026-09-27)
- **Goal — fetch and return:** the sloth goes down through the floors, gets something precious at the bottom, then has to make it back up.
- **Progression — XP → gear:** XP is earned during a floor; at the end of each floor you choose gear with it.
- **Rest (nap):** rest mid-floor to recover so you can keep exploring — but enemies may find you asleep.
- **Hook — stillness = stealth:** staying still builds camouflage and enemies lose track of you; moving or attacking breaks it.

### Open design questions (decide at the milestone shown)
- What is fetched, and why? (theme/story — before M9)
- How many floors down? Is the way back the same floors (remembered, now harder) or new ones? (M9)
- ~~What does resting restore~~ → nap heals 1 HP/turn; a bite on a sleeping sloth is a guaranteed double hit (M7, decided)
- XP → gear: XP as a currency to buy gear, or pick 1 of 3 offers when you reach a threshold? (M8)
- ~~Stillness: how many turns to hide~~ → 3 turns; only works out of sight (M6, decided)

## Milestones
- [x] 1. Setup: project, Git, pixel-art settings, docs, sprites imported
- [x] 2. The @ moves: sloth on a grid, one tile per key press
- [x] 3. A map: hand-made floors and walls; walls block movement
- [x] 4. Procedural dungeon: rooms and corridors (random rooms, then BSP)
- [x] 5. Field of view: shadowcasting, visible + explored tiles
- [x] 6. Enemies and turns: turn manager, chase AI, blocking, stillness camouflage (hook)
- [x] 7. Combat: dice combat box (claw/shell/leaf vs bite), reroll, HP, death, message log, XP from leaves, nap
- [x] 8. Home & trips: tree-house hub, ladder home / stairs down, furniture crates + bonuses, computer shop (3 upgrades), macaw delivery
- [x] 9. Deeper: depth scaling (new monsters, tougher dice), more furniture, floor pickups
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
