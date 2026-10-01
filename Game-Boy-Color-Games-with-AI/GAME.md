# ENGINE LAB (test cart)

A small platformer, a streamed open-world RPG and a set of stress tests. It exercises every engine module and
pushes the GBC's CPU, RAM (WRAM banks, cartridge SRAM, VRAM bank 1) and ROM (2 MB, 124 of 128 MBC5 banks used)
to their limits.

## Genre and goal
- **Play**: reach the cave through the door at the end of the level and grab the trophy. Collect coins, hit
  `?` blocks, stomp slimes. 3 lives. The best result is saved in battery RAM.
- **Play game 2** (ROM size stress): explore a 128x96-screen top-down world (1.5 MB of map data, one ROM bank per
  row of screens): 137 towns joined by roads, forests, lakes, mountains, snow in the north, desert in the south.
  Read signposts (they point to the nearest town) and knock on doors. No goal: it is a streaming test you can walk.
- **Stress tests**: SPRITE, SCROLL and CPU scenes show live CPU load (`CPU avg% PK peak% fps`, see
  `src/game/meter.c`). MEMORY runs a full RAM/ROM test. SOUND plays every song and SFX.

## Controls
| Button | Play | Stress scenes |
|---|---|---|
| D-pad | walk (LEFT/RIGHT), UP reads signs / opens doors | change load (see each scene's help line) |
| A | jump (hold for higher), advance dialogs | cycle mode |
| B | - | second toggle |
| SELECT | - | third toggle |
| START | pause menu (`dialog_choice`) | back to the menu |

Play game 2: D-pad walk (hold B to run, 2 px per frame), A reads the sign / knocks on the door in front, SELECT
cycles the view WALK -> STATS -> FLY (no collision, the hero hovers, 4 px per frame, 8 with B), START back to the menu.
HUD: area name + screen x,y; STATS and FLY add `BK` (ROM bank of the player's row), `LD` (screens loaded from ROM),
`ST` (stalls: loads forced by a read, see Overworld streaming) and the CPU meter.

## Scenes
1. **title** (`src/scenes/title.c`): LAB logo map, hero tweened in, brick palette cycling, counts the boot in SRAM.
2. **menu** (`menu.c`): `menu_run` with 8 options, cartridge header info (ROM size, banks), save stats.
3. **level / cave** (`play.c`): shared gameplay. Level 120x24 (scrolls both axes), cave 40x18 (purple UI colors).
4. **win** (`win.c`): stats, best result saved, fireworks. **gameover** (`gameover.c`): `input_wait_press`.
5. **sprites** (`stress_sprites.c`): up to 64 balls through `spr_put`; BOUNCE / LINE (10-per-scanline limit) / RAIN;
   FLICKER rotates draw order so balls over the 40/10 limits flicker instead of vanishing.
6. **scroll** (`stress_scroll.c`): 200x64 map (max width), Lissajous camera up to 8 px/frame on both axes, manual mode, shake.
7. **cpu** (`stress_cpu.c`): 1-32 bodies with tile collision, FX (particle fountain / 8 tweens), SPARE loop
   (mul/div iterations left in the frame), single/double speed switch.
8. **memory** (`memtest.c`): WRAM banks 1-7, bank switching, SRAM, VRAM bank 1, ROM blobs (all byte-exact).
9. **sound** (`sound.c`): 5 songs, 9 SFX, NR52 channel activity.
10. **rpg** (`rpg.c`, menu "PLAY GAME 2"): top-down hero on the overworld streamed by `src/game/overworld.c`,
   music `mus_level`.

## Entities and game logic
- `src/game/player.c`: hero body 10x14 in a 16x16 sprite, accel/friction, variable jump (4 tiles), spring (9 tiles).
- `src/game/enemies.c`: up to 6 slimes; turn at walls and ledges; stomp from above (+100), side touch hurts.
  Slimes more than ~32 px off screen are frozen, and each runs its physics every other frame (Performance).
- `src/game/coins.c`: coin sprites from SPAWN2 markers (char `o`), collected mask per area in `state.c` (survives the cave trip),
  tweened "pop" coin for `?` blocks.
- `src/game/state.c`: score, lives, coins, frames, `g_enter`, coin masks, used blocks, checkpoint.
- `src/game/save.c`: `save_t` at SRAM 0xA000 with magic `LAB1` and checksum: boots, saves, best coins/time, wins.
- `src/game/meter.c`: CPU load = scanlines used since VBlank (LY) / 154; an update that passes the next VBlank = 100%.
- `src/game/romcheck.c` (**not banked**): verifies ROM blobs; it switches the 0x4000 window, so it can't live there.
- `src/game/fx.c` (**not banked**): particle styles, read every frame by `particles_update` from any bank.
- Hazards and falls: burst, lose a life, respawn at the checkpoint (level) or the area entry. Enemy touch: knockback.
- `src/scenes/rpg.c` (play game 2): hero hitbox 10x8 at the feet of a 16x16 sprite, axis-separated 1 px steps
  against metatile collision (`ow_coll`, 4 corners), slides 1 px around corners, A probes the cell 4 px ahead.
- `src/game/overworld.c`: world streaming (next section). `src/game/romcopy.c` (**not banked**): `rom_copy`, copies
  const data from any ROM bank to RAM (world screens, the overworld tileset, which live in other banks).

## Overworld streaming (play game 2)
- World: 128x96 screens; a screen = 10x9 metatiles of 16x16 px = one GB screen. `assets/world/world_rNN.c` = row NN
  of screens = 128 records of 128 bytes (`wscreen_t`: 90 metatile chars, name, sign text) = exactly one 16 KB bank.
  The bank of each row comes from the linker (`&__bank_world_rNN` table in `overworld.c`).
- A 3x3 ring of screens around the player's screen lives in WRAM (9 slots x 128 bytes). When the player's center
  crosses into another screen, the ring re-centers: screens still inside keep their slot, the 3 (5 diagonally) that
  left are dropped and the new ones are queued, then loaded **one per frame** (copy 128 bytes + translate 90 chars to
  metatile ids, ~5K cycles). The camera always centers the player (clamped at the world's edge).
- Stall: reading a queued screen (a new BG column/row, or collision) loads it on the spot and counts in `ST`. At
  8 px per frame the queue needs at most 5 frames and a new screen takes 9+ frames to come into view, so in play it
  stays 0; it only triggers if the player crossed two screens faster than that. Tested by corrupting the queued
  slots in the emulator: every forced load happened, the screen stayed exact.
- BG: like the engine map module (7.6) but read from the ring: `ow_update` gathers the new column/row (metatile id
  << 2 | quadrant, then two table lookups), `ow_flush` writes them first thing in the next update (GDMA for rows).
  The engine map module isn't used (maps are at most 200x200 tiles; this world is 2560x1728).
- RAM: the ring and its tables sit at fixed addresses in WRAM bank 1, D000-D6DF (`__at`), outside the linker's
  RAM areas. The memory test overwrites them; `ow_init` rebuilds everything on every scene start.
- The world rows were produced once by a throwaway Node generator (value-noise continent, biomes by latitude and
  moisture, towns on a 6-screen spacing, roads by A* over a minimum spanning tree, bridges over water). It is not
  kept (golden rule 1); the rows are plain text and can be edited by hand. Row files include `<gb/gb.h>`, not
  `engine.h`: see docs/banking.md 10.

## Code banking (bank 0 is full)
The engine + GBDK take ~14.7 KB of the 16 KB fixed bank, so almost all game code and data is banked
(`#pragma bank 255`, `BANKED` functions). `src/scenes/scene_table.c` (not banked) holds every `scene_t` with tiny
stubs that make the `BANKED` calls. Rules used (docs/banking.md 10.1):
- Const data is read only by code in its own file/bank, or by an engine loader given `BANK(x)`.
- Data shared across banks lives in RAM (`nobody` in play.c) or bank 0 (`fx.c`, music, SFX), or is copied to RAM
  with `rom_copy` (the overworld tileset and world screens).
- Code that switches the 0x4000-0x7FFF window (`romcheck.c`, `romcopy.c`) is not banked.
Bank 0 free: 120 bytes. Game RAM ends at 0xCCD4 (about 3 KB of globals), below 0xD000 (required by the WRAM test,
see Memory test). ROM: banks 0-123 of 128 (2 MB file), bank 123 half free; 4 more banks fit before the 4 MB size.

## Memory test
- WRAM D000-DBFF of banks 1-7: `wram_chunk()` uses only statics, disables interrupts, never calls, restores
  bank 1 before returning (the stack lives at the top of D000-DFFF). DC00-DFFF is left for the stack.
  Requires all game globals below 0xD000: check `_DATA` + `_INITIALIZED` end in a `-Wl-m` map after adding RAM.
- SRAM A100-BFFF (the save at A000 is kept), VRAM bank 1 tiles 0-127, ROM blobs 1-24 (`assets/romtest/`).
- Measured in the headless emulator: all PASS, 0 errors, 259 frames (~4.3 s).

## Assets
| File | Contents |
|---|---|
| `assets/fonts/font_main.c` | Font (ASCII 32-127), dialog box tiles, `sfx_menu` (engine UI) |
| `assets/maps/map_world.c` | World tileset (24 tiles, 7 palettes) + maps title, level, cave, arena (one bank) |
| `assets/maps/map_scroll.c` | 200x64 scroll stress map + its 3-tile, 7-palette tileset (one bank) |
| `assets/sprites/spr_hero.c` | 16x16, 4 frames (idle, walk A, walk B, jump), OBJ 0 |
| `assets/sprites/spr_slime.c` | 16x8, 2 frames, OBJ 1 |
| `assets/sprites/spr_coin.c` | 8x8, 3 frames spin, OBJ 2 |
| `assets/sprites/spr_ball.c` | 8x8 stress ball, OBJ 3 (stress scenes recolor with OBJ 4-5) |
| `assets/sprites/spr_spark.c` | 8x8 particle, 3 frames, OBJ 6 |
| `assets/music/mus_title.c` `mus_level.c` `mus_cave.c` `mus_win.c` `mus_over.c` | songs (not banked) |
| `assets/sfx/sfx_all.c` | jump, coin, hurt, bump, spring, flag, stomp, boom (not banked) |
| `assets/romtest/rom_blob.h`, `rom_blob_01..24.c` | ROM stress: 24 banks x 15872 bytes of formula data (game-specific folder, delete with the game) |
| `assets/tilesets/ts_overworld.c` | Play game 2: 68 BG tiles, 7 BG palettes, 19 metatiles (`ow_metatiles`: char, coll, tag, 4 tiles, 4 attributes) |
| `assets/sprites/spr_rpg_hero.c` | 16x16 top-down hero, 6 frames (down, down step, up, up step, right, right step), OBJ 0 |
| `assets/world/world.h`, `world_r00..95.c` | Play game 2 world: 96 banks x 128 screens (format in `world.h`; game-specific folder, delete with the game) |

## Art source
All art is AI-drawn (docs/graphics.md 8). `resources/` is empty.

| Source (`resources/`) | Becomes | Notes |
|---|---|---|
| - | - | - |

## Tile flags
The engine knows no tile flags (CLAUDE.md section 5): each one became a legend byte or a map character.
| Flag | Meaning in this game | Became |
|---|---|---|
| SOLID | ground, bricks, blocks, rock, spring | `COLL_SOLID` |
| ONEWAY_U | planks (`=`), up gate (`A`) | `COLL_TOP` |
| ONEWAY_R / ONEWAY_L / ONEWAY_D | gates `>` `<` `V` | `COLL_RIGHT` / `COLL_LEFT` / `COLL_BOTTOM` |
| OVER | bushes, tall grass, crystals | `MAP_OVER` |
| HAZARD | spikes (`^` `w`), lava (`L`): lose a life | `TAG_HAZARD` |
| SPAWN0 | player start (level `P`) | char `P` (`map_find`) |
| SPAWN1 | slime (`s`) | char `s` (`scan_map`) |
| SPAWN2 | coin (`o`) | char `o` (`scan_map`) |
| TRIGGER0 | sign (`S`): UP shows its text; the level's 3rd sign writes the SRAM save (`dialog_choice`) | `TAG_SIGN` |
| TRIGGER1 | trophy (`T`, cave): win | `TAG_TROPHY` |
| TRIGGER2 | checkpoint flag (`F`, level): respawn point | `TAG_CHECK` |
| LEAVE0 | door (`D`): level -> cave ENTER0; cave -> level ENTER1 (UP to enter) | `TAG_DOOR` |
| ENTER0 | cave arrival (`e` in the cave) | char `e` |
| ENTER1 | level arrival next to the door (`e` in the level) | char `e` |
| 31 | bump block, map char `?`: hit from below -> coin, drawn as `u` (used) with `map_set_tile`, re-applied after streaming | char `?` |
| 32 | spring, map char `z`: landing on it launches the player ~9 tiles | char `z` |

Play game 2 metatiles (legend `ow_metatiles`, one char per 16x16 cell; reuses the tag bits above):
| Flag | Meaning in play game 2 | Became |
|---|---|---|
| SOLID | water `~`, trees `T` `P` `A`, cactus `c`, mountain `M`, house `R r H D`, sign `S` | `COLL_SOLID` |
| TRIGGER0 | sign `S`: A shows its screen's sign text | `TAG_SIGN` |
| LEAVE0 | door `D`: A shows a knock message (houses can't be entered) | `TAG_DOOR` |
| SPAWN0 | player start: HAWKHOLM plaza, screen 62,45 cell 4,4 | `WORLD_START_*` in `world.h` |
Walkable: grass `.`, tufts `,`, flowers `*`, sand `s`, road `=`, bridge `#`, snow `_`, pavement `p`.

## Palette plan
| Slot | BG | OBJ |
|---|---|---|
| 0 | ground (sky, grass, dirt) | hero |
| 1 | stone / bricks / clouds (title cycles colors 2-3) | slime |
| 2 | gold (planks, ? blocks, spring, sign, door) | coin |
| 3 | red (flag, lava outdoors) | ball (stress) |
| 4 | cave rock | ball blue (sprite stress) |
| 5 | cave gold (lava, trophy, planks, door in the cave) | ball green (sprite stress) |
| 6 | leaves (bushes, tall grass) | spark particles |
| 7 | UI / text (purple in the cave via `text_set_colors`) | - |
The scroll map uses its own 7 hue palettes in BG 0-6.
Play game 2 BG: 0 grass, 1 water, 2 sand/road/bridge/cactus, 3 stone (mountain, pavement), 4 snow, 5 house,
6 flora (flowers, signs); OBJ 0 hero.

## VRAM budget (per scene)
| Scene | Sprite tiles (≤128) | BG tiles (≤128) | BG pals (≤7) | OBJ pals (≤8) |
|---|---|---|---|---|
| title | 16 | 24 | 7 | 1 |
| level / cave | 26 (hero 16, slime 4, coin 3, spark 3) | 24 | 7 | 4 |
| win | 3 | 0 | 0 | 1 |
| sprites | 4 | 0 | 0 | 4 |
| scroll | 0 | 3 | 7 | 0 |
| cpu | 4 | 24 | 7 | 2 |
| memory | 0 (tests free bank-1 tiles 0-127) | 0 | 0 | 0 |
| rpg | 24 (hero) | 68 | 7 | 1 |
Worst scanline in play: hero 2 + 2 slimes 4 + coins; stays under 10.

## Performance (measured in tests/engine/gbc.mjs, CGB double speed = 140,448 cycles per frame)
Engine cost per call: see docs/debugging.md 13.1 (kept up to date there).

| Load | CPU | FPS |
|---|---|---|
| sprites: 16 / 24 / 32+ balls | 54% / 79% / 100% | 60 / 57 / ~30 |
| cpu: 4 / 5 / 6 / 7 bodies, no FX | 65% / 82% / 97% / 100% | 56 / 52 / 41 / 30 |
| cpu: 4 bodies + fountain or 8 tweens / both | 100% | 30 / 20 |
| scroll: max speed (1 column + 1 row per frame) | avg 28%, peak 54% (whole frame incl. `map_flush`) | 60 |
| play: level, running and jumping | ~88K cycles (63%) average | 60; ~1.5% single dropped frames (coin pickups) |
| play game 2: walking / running | avg 17%, peak 43% | 60 |
| play game 2: FLY at 8 px per frame, diagonal (a screen every ~18 frames) | avg 15%, peak 50-58% | 60 |
| play game 2: every queued screen forced to stall (emulator test) | avg 44%, peak 76% | 59 |

Game-side rules that keep play near 60 fps: cull coins in 8-bit tile units before any 16-bit math, draw 1x1
sprites with `spr_put`, `rect_overlap` only near the hero, freeze off-screen slimes, half-rate slime physics,
one map scan on load (no `map_find` per object), text only when a value changes and one item per frame (the HUD
prints at most one changed value per frame; the timer divides once a second).
The sprite and cpu rows were measured before the engine speedups of 2026-09 (spr_put, particles, streaming);
they are now lower. Play before them: 85% average, 204 of 1,358 frames dropped, in bursts while scrolling.

## Music and SFX
| Song | Key, tempo | Loop | Used in |
|---|---|---|---|
| `mus_title` | C major, fpt 6 (150 BPM) | 32 ticks | title, menu |
| `mus_level` | G major, fpt 7 (128 BPM) | 64 ticks | level |
| `mus_cave` | A minor, fpt 9 (100 BPM), CH1 echo | 32 ticks | cave |
| `mus_win` | C major, fpt 5 | no loop | win |
| `mus_over` | A minor, fpt 10 | no loop | game over |
SFX: jump 1, coin 2, hurt 3, bump 1, spring 2, flag 2 (CH1); stomp 2, boom 3 (CH4).
