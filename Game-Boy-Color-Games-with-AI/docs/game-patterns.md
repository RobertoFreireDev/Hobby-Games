# Game patterns, optimization and lessons learned

Read when: starting a new game (before filling in `GAME.md`), designing a scene or an entity system, a scene drops
frames, bank 0 or RAM runs out, or a map is too big for the engine's map module.

## 14. Game patterns, optimization and lessons learned

This file holds what was learned building games on this engine, so it survives when the game is deleted
(CLAUDE.md section 2, "start over"). It is **game-side** knowledge: how to use the engine well, not how the
engine works (that is [engine-api.md](engine-api.md)).

Sources:
- **ENGINE LAB** (commits `dd41054`–`ba24b22`): a platformer (level + cave), a streamed 2 MB open-world RPG
  ("PLAY GAME 2"), and sprite/scroll/CPU/memory/sound stress scenes. All code banked.
- **CRITTER QUEST** (never committed): a 32 KB unbanked monster-catching RPG with a grid overworld, battles and
  type chart.

The snippets below are complete enough to reuse. The original files can be read with `git show ba24b22:<path>`
(e.g. `git show ba24b22:src/game/overworld.c`).

Cycle costs quoted here come from the headless emulator (`tests/engine/gbc.mjs`), measured after the engine
speedups of 2026-09-27. A frame at CGB double speed is **140,448 cycles**; VBlank is ~9,100, of which ~7,300 remain
after the VBlank interrupt. The per-call reference table is [debugging.md](debugging.md) 13.1.

---

### 14.1 Decide before writing code

**1. Banked or not.** This decision shapes every header, so make it first, and write it in `GAME.md`.

| Plan | Game code + data | What bank 0 holds for the game |
|---|---|---|
| Unbanked | Everything fits in 32 KB (0x0000–0x7FFF). CRITTER QUEST (6 critters, 4 maps, battles, 4 songs) came to exactly 32 KB | Everything; nothing else to do |
| Banked | Anything past 32 KB | Only **~1.2 KB**: once anything is banked, bank 0 (16 KB) holds the engine, the font and GBDK (~15 KB) plus the game's bank-0 parts |

If the game might grow past ~4 maps, 2 tilesets or ~10 KB of code, **bank from the first file**: `#pragma bank 255`
in every game file, `BANKED` functions, and a non-banked scene table (14.3). Converting an unbanked game later
means editing every header and moving shared data.

What had to stay in bank 0 in ENGINE LAB (measured object sizes, 1,154 bytes in all):

| Item | Bytes | Why it can't be banked |
|---|---|---|
| Scene table (12 scenes, 26 stubs) | 274 | The scene manager calls through plain function pointers (14.3) |
| Music (5 songs) | 46–139 per song, 406 in all | The audio driver reads it from the VBlank interrupt, whatever bank is mapped |
| SFX (8 effects) | 99 | Same |
| Code that switches the 0x4000 window (`rom_copy`, ROM checker) | 43 / 188 | It would unmap itself |
| Particle styles + their `sprite_t` handle | 32 | `particles_emit` is called from several banks |
| Every file that includes `engine/engine.h` | 2 per file | GBDK's `emu_debug.h` defines an initialized static in each one |

So songs and effects are cheap (reuse them anyway: the RPG had to reuse `mus_level` because bank 0 was full), and
the scene table is the cost that grows with the game: about 23 bytes per scene.

**2. RAM.** ENGINE LAB used ~3 KB of globals. Big buffers that one scene needs (a streamed world, a battle's work
area) go at fixed addresses in WRAM bank 1 (`__at(0xD000)`), outside the linker's RAM areas, and are rebuilt in
that scene's `enter`. After adding RAM, check where `_DATA` + `_INITIALIZED` end in a `-Wl-m` map.

**3. CPU per scene.** Add up the per-frame cost of everything on screen at the worst moment (14.2) before
designing the level. Aim for **≤ 65% average** in the main play scene: one-off costs (a pickup, a new BG column,
a death burst) land on top of the average, and a scene at ~85% drops frames in bursts that the player feels as a
short slowdown.

**4. The per-scene VRAM/palette budget** table in `GAME.md` (CLAUDE.md 12.0), and the worst scanline.

---

### 14.2 Frame budget in practice

| Work, per frame | Cycles | % of a frame |
|---|---|---|
| `spr_put` (one 8×8) | ~560 | 0.4 |
| `spr_draw` 16×16 (2×2) / 24×16 (3×2) | ~2,600 / ~3,100 | 1.8 / 2.2 |
| `anim_update` | ~1,000 | 0.7 |
| `body_move` (8×8 to 10×14 body) | ~10,000 | 7 |
| `body_touch_tags` / `body_on_ground` | ~4,000 / ~2,700 | 3 / 2 |
| `body_overlap` / `rect_overlap` called from banked code | ~1,250 / ~6,000 | 1 / 4 |
| `tween_update`: nothing active / per active tween | ~200 / ~3,400 | 0.1 / 2.4 |
| `particles_update` per live particle (pool of 12) | ~2,700 | 2 |
| `particles_emit` per particle | ~2,200 | 1.6 |
| Camera crosses a tile: new column (gather + flush) | ~12,700 + ~5,900 | 13 |
| Camera crosses a tile: new row (gather + flush) | ~10,800 + ~1,000 | 8 |
| `text_print_num` (5 digits) / per printed char | ~11,000–13,500 / ~2,500 | 9 / 1.8 |
| `gfx_set_*_palette` while not fading | ~1,800 | 1.3 |
| `map_find` / `map_find_tag` | ~120 per cell scanned | 120×24 map: ~2.5 frames |
| One `/` or `%` (library call) / GBDK 8×8 multiply | ~1,000+ / ~555 | |

A typical platformer actor (physics + touch test + animation + 16×16 draw) costs **~18,000 cycles, 13%**. So a
play scene holds the player plus ~3–4 actors doing full tile physics, plus coins, particles and a HUD. Everything
beyond that has to use the tricks in 14.4.

ENGINE LAB results:

| Scene | Load | Result |
|---|---|---|
| Platformer, first version (everything simulated, HUD reprinted) | ~340K cycles | ~20 fps |
| Platformer after the 14.4 rules + engine speedups | 63% average | 60 fps, isolated single dropped frames on coin pickups |
| Open-world RPG, walking / flying 8 px per frame diagonally | 17% / peak 58% | 60 fps |
| Scroll stress, 1 row + 1 column every frame | 28% average, 54% peak | 60 fps |

Compiler flags don't help: `--max-allocs-per-node50000` changed costs by under 1%. The cost is in what the code
does, so the fixes are design fixes.

---

### 14.3 Scene structure

**Frame order in `update`** (the order matters for correctness, not only speed):
1. Counters and timers.
2. Blocking UI (`dialog_*`, `menu_run`, pause) **before** `cam_follow`. Blocking calls don't flush the pending
   BG line; opening one after `cam_follow` needs `map_flush()` first (engine-api.md 7.6).
3. Player input and physics, then the world's objects.
4. `cam_follow`, then anything that depends on the camera (re-applying changed tiles, 14.5).
5. Draw: **player first** (drawn first = on top), then pickups, enemies, `particles_update()` last.
6. `tween_update()`.
7. HUD last, at most one changed item (14.6).

**The first `update` runs before the fade-in.** `scene_goto` calls `enter()`, then `update` once, then fades in.
A scene whose update blocks (`menu_run`) must skip its first call, or the menu runs on a black screen:
```c
static uint8_t first;
void menu_enter(void) BANKED { /* ...labels... */ first = 1; }
void menu_update(void) BANKED {
    if (first) { first = 0; return; }                 /* let the fade-in finish before blocking */
    switch (menu_run(3, 4, options, 8)) { /* ... */ }
}
```
The scene manager also copies `keys` into `keys_prev` on a transition, so the press that changed scene doesn't
fire again in the new one.

**`enter` loads everything while the screen is black**, in this order: `map_load` (tileset + BG palettes),
`gfx_load_sprite` once per sprite asset (share the handle between all its instances), one map scan for objects
(14.5), place the player, `cam_set`, HUD and labels, `music_play`. BG text goes after `cam_set`, which redraws
the whole BG.

**`leave`** undoes what the scene changed globally: `text_set_colors(pal_ui_default)`, `HIDE_WIN`.

**One gameplay file, several scenes.** The level and the cave shared `play.c`: `level_enter()` and `cave_enter()`
call `play_enter(area)`, and both `scene_t` use the same `update`/`leave`. The area picks the map, music and UI
colors.

**Banked scenes: the scene table.** The engine calls `scene_t` members through plain function pointers, which
can't reach a switchable bank. Keep every `scene_t` in one **non-banked** file with stubs that make the `BANKED`
call (docs/banking.md 10.1):
```c
/* src/scenes/scene_table.c: NOT banked */
#include "engine/engine.h"
#include "scenes.h"
static void title_e(void) { title_enter(); }   static void title_u(void) { title_update(); }
static void level_e(void) { level_enter(); }   static void cave_e(void)  { cave_enter(); }
static void play_u(void)  { play_update(); }   static void play_l(void)  { play_leave(); }
const scene_t scene_title = { title_e, title_u, 0 };
const scene_t scene_level = { level_e, play_u, play_l };
const scene_t scene_cave  = { cave_e,  play_u, play_l };
```
```c
/* src/scenes/scenes.h */
extern const scene_t scene_title, scene_level, scene_cave;
void title_enter(void) BANKED;  void title_update(void) BANKED;
void level_enter(void) BANKED;  void cave_enter(void) BANKED;
void play_update(void) BANKED;  void play_leave(void) BANKED;
```

**Scene links (LEAVE/ENTER).** `state.c` holds `g_enter`, the arrival the next scene uses. A sentinel means
"new game, use the start point":
```c
#define ENTER_START 0xFF                                   /* state.h */
/* leaving through a door: GAME.md says level LEAVE0 -> cave ENTER0, cave LEAVE0 -> level ENTER1 */
if ((f & TAG_DOOR) && KEY_PRESSED(J_UP)) { g_enter = area ? 1 : 0; scene_goto(area ? &scene_level : &scene_cave, TRANS_FADE_WHITE); }
/* arriving (enter): each area has one arrival char 'e'; a new game uses SPAWN0 'P' */
if (g_enter == ENTER_START || !map_find('e', 0, &tx, &ty)) map_find('P', 0, &tx, &ty);
```

**State that survives scenes** (score, lives, what was collected, checkpoints) lives in `src/game/state.c` with one
`state_new_game()` that resets it. A per-area "collected" bitmask (`uint32_t coins_taken[AREAS]`) keeps coins
gone after a trip through a door and back.

**Title screen idioms.** Blink "PRESS START" with `(t & 31) == 0` print / `== 16` `text_clear`; call `rand_seed()`
on the START press (the frame count gives the entropy); count the power-on in SRAM once per boot with a `booted`
flag in RAM.

---

### 14.4 Entities and making them cheap

**Pools.** Fixed arrays of structs with an `active` flag, walked with a `uint8_t` index and one struct pointer:
```c
typedef struct { uint8_t active; body_t b; int8_t dir; anim_t anim; } slime_t;
static slime_t slimes[MAX_SLIMES];
for (i = 0; i < MAX_SLIMES; i++) { s = &slimes[i]; if (!s->active) continue; /* ... */ }
```

**Hitbox smaller than the sprite**, and a fixed draw offset:
- Platformer hero: 10×14 body in a 16×16 sprite, drawn at `x - 3, y - 2`. Spawn from a tile:
  `x = FIX(tx * 8 + 3)`, `y = FIX(ty * 8 + 8 - 14)` (feet on the tile's bottom).
- Top-down hero: 10×8 hitbox **at the feet**, sprite drawn at `x - 3, y - 8`, so the head can overlap walls and
  trees above it, which reads correctly from above.
- Slime: 14×7 in a 16×8 sprite.

**The rules that took the platformer from 20 to 60 fps:**
1. **Freeze what's off screen.** Don't simulate or draw actors more than ~32 px outside the view:
   ```c
   #define NEAR_SCREEN(b) (UNFIX((b).x) > cam_x - 48 && UNFIX((b).x) < cam_x + 192 && \
                           UNFIX((b).y) > cam_y - 40 && UNFIX((b).y) < cam_y + 176)
   ```
2. **Half-rate physics for slow movers**, half of them each frame, so the cost is even. Double the speed to
   compensate (0.5 px per frame = `vx` 16 every other frame):
   ```c
   tick++;
   /* in the loop, after anim_update */
   if ((tick ^ i) & 1) continue;
   ```
3. **Static objects are not bodies.** Coins keep `uint8_t` tile coordinates only. Cull in 8-bit tile units
   first, draw 1×1 sprites with `spr_put` (not `spr_draw`), and run `rect_overlap` only when the object is in the
   3×3 tiles around the player:
   ```c
   ctx = (uint8_t)((uint16_t)cam_x >> 3); cty = (uint8_t)((uint16_t)cam_y >> 3);
   htx = (uint8_t)((uint16_t)UNFIX(b->x) >> 3); hty = (uint8_t)((uint16_t)UNFIX(b->y) >> 3);
   for (i = 0; i < coin_n; i++) {
       if (!coin_live[i] || (uint8_t)(coin_tx[i] - ctx + 1) > 21 || (uint8_t)(coin_ty[i] - cty + 1) > 19) continue;
       /* ... exact screen position, then: */
       if ((uint8_t)(coin_tx[i] - htx + 1) <= 3 && (uint8_t)(coin_ty[i] - hty + 1) <= 3 && rect_overlap(...)) { /* take */ }
       spr_put(tile, sx, sy, coin_spr.pal);
   }
   ```
   `(uint8_t)(v - lo + 1) <= n` is a whole range test in one unsigned byte compare.
4. **One animation for identical objects.** All coins share one `anim_t` (one `anim_update` per frame). For
   enemies, stagger them instead (`s->anim.i = i & 1`) so they don't move in step.
5. **Copy 32-bit masks to bytes on load.** `coin_live[i] = !(mask & ((uint32_t)1 << i))` once in `coins_add`; per
   frame, test the byte. 32-bit shifts per object per frame are expensive.
6. **Check a map char only when an event happens.** The spring (`'z'`) is read only when `body_move` returns
   `HIT_DOWN`; the bump block (`'?'`) only on `HIT_UP`, at the hitbox's two top corners. Neither needs a tag bit.
7. **Cheap distance first**, then `body_overlap` / `rect_overlap`.

**Platformer feel that worked** (fixed 12.4, `FIX(1)` = 16):

| Constant | Value | Result |
|---|---|---|
| Gravity | 5 per frame | |
| Max fall | `FIX(4)` | |
| Walk max / accel | 24 (1.5 px/frame) / 3, with `approach(vx, target, ACCEL)` | Short slide on stop |
| Jump | `vy = -72` (4.5 px/frame) | ~4 tiles high |
| Variable jump | on A release while `vy < 0`: `vy = -((-vy) >> 1)` | Tap = short hop |
| Spring | `vy = -112` (7 px/frame) | ~9 tiles; **every speed must stay below `FIX(8)`** (`body_move` limit) |
| Stomp | falling and `feet <= enemy top + 4` | Bounce `-FIX(3)`, or a full jump if A is held |
| Hurt | knockback `±FIX(2)`, `vy = -FIX(2)`, 90 frames invulnerable, blink with `invuln & 4` | |

**Death without a scene change.** Emit a burst, `cam_shake`, hide the hero, count `dead` down while the world
keeps running, then respawn at the checkpoint and `cam_set` (a teleport needs a full redraw; `cam_follow` moves at
most 8 px per frame). A fall is `hero y > map_h_px`.

**Top-down movement with corner sliding.** Move 1 px at a time per axis against the collision query; when blocked,
slide 1 px sideways if 5 px that way would clear the corner. Running = 2 steps per frame:
```c
static void step(int8_t dx, int8_t dy) {
    uint16_t nx = hx + dx, ny = hy + dy;
    if (!blocked(nx, ny)) { hx = nx; hy = ny; return; }
    if (dx) {
        if (!blocked(nx, hy - 5) && !blocked(hx, hy - 1)) hy--;
        else if (!blocked(nx, hy + 5) && !blocked(hx, hy + 1)) hy++;
    } else {
        if (!blocked(hx - 5, ny) && !blocked(hx - 1, hy)) hx--;
        else if (!blocked(hx + 5, ny) && !blocked(hx + 1, hy)) hx++;
    }
}
/* per frame: for (i = 0; i < speed; i++) { if (dx) step(dx, 0); if (dy) step(0, dy); } */
```
Interaction (A) probes the cell 4 px past the hitbox edge the player faces. A top-down walk cycle fits in 6
frames: down, down step, up, up step, side, side step. The step frames alternate with `SPR_FLIPX` for the other
foot, and left is the side frames flipped.

**Grid movement** (CRITTER QUEST): walking one 16 px cell per move, with the random-encounter roll made once per
grass cell entered (1 in 8 there, e.g. `(rand() & 7) == 0`), is simpler than free movement and keeps the
encounter rate independent of walking speed.

---

### 14.5 Maps, tiles and flags in practice

- **Scan the map once on load** and keep what you find in small arrays. `map_find` rescans from the top every call;
  keep it for single lookups on small maps.
  ```c
  static void scan_map(void) {
      uint16_t x, y, w = map_w_px >> 3, h = map_h_px >> 3;
      char c;
      for (y = 0; y < h; y++)
          for (x = 0; x < w; x++) {
              c = map_char(x, y);
              if (c == 'o') coins_add(x, y);
              else if (c == 's') slimes_add(x, y);
              else if (c == 'S' && sign_n < MAX_SIGNS) { sign_tx[sign_n] = (uint8_t)x; sign_ty[sign_n] = (uint8_t)y; sign_n++; }
          }
  }
  ```
  Spawn markers use a legend entry that draws the floor tile under them.
- **Tag bits only for flags tested while playing** (hazard, sign, door, checkpoint, trophy), and **one
  `body_touch_tags` per body per frame**, then test the bits:
  ```c
  f = body_touch_tags(&hero.b);
  if ((f & TAG_HAZARD) || UNFIX(hero.b.y) > (int16_t)map_h_px) die();
  else {
      if ((f & TAG_SIGN) && KEY_PRESSED(J_UP)) read_sign();
      if (f & TAG_TROPHY) scene_goto(&scene_win, TRANS_FADE_WHITE);
  }
  ```
  Several signs share one tag: find which one with the stored coordinates (the sign whose column is under the
  hitbox), and keep the texts in a table in the same order as the scan found them.
- **`map_set_tile` is visual only**, and streaming redraws cells from the map data. Keep the change in game state
  and re-apply it when the camera reaches a new tile:
  ```c
  static void refresh_blocks(uint8_t force) {
      uint16_t ctx = (uint16_t)cam_x >> 3, cty = (uint16_t)cam_y >> 3;
      if (!force && ctx == last_ctx && cty == last_cty) return;
      last_ctx = ctx; last_cty = cty;
      for (i = 0; i < block_n; i++) if (blocks_used & (1 << i)) map_set_tile(block_tx[i], block_ty[i], 'u');
  }
  ```
  Call it after `cam_follow` every frame, and with `force` after `cam_set`.
- **Map characters to avoid:** `"` must be escaped as `\"` in a C string, and `\` starts an escape. Unknown chars
  draw as blank with no collision, so a typo shows up as a hole, not a build error.
- **`MAP_OVER`** (bushes, tall grass) hides the sprite's pixels behind the tile's colors 1–3; color 0 of an OVER
  tile stays see-through. Tall grass drawn this way hides the legs of a top-down hero.
- **The engine's map is at most 200×200 tiles.** For anything bigger, stream screens yourself (14.8).
- In tests, tile 128 equals `TILE_BLANK`: check the attribute byte (0 vs `ATTR_BLANK` 0x0F) to tell a drawn
  first-tile cell from an empty one.

---

### 14.6 Text, HUD and UI

Text costs ~2,500 cycles per character (two VRAM writes per char), so:
- **Print labels once**, in `enter` or when the HUD is (re)shown; per frame, print only values that changed.
- **At most one changed item per frame**, round-robin. A coin pickup used to reprint the whole HUD in the same
  frame that emitted particles:
  ```c
  static const uint8_t hud_x[4] = { 2, 7, 11, 17 }, hud_len[4] = { 2, 1, 5, 3 };
  static void hud_draw(void) {                    /* called when hud_dirty */
      uint8_t n, i; uint16_t v;
      for (n = 0; n < 4; n++) {
          i = hud_next; hud_next = (i + 1) & 3;
          v = hud_value(i);
          if (v != hud_shown[i]) { hud_shown[i] = v; text_print_num_win(hud_x[i], 0, v, hud_len[i]); return; }
      }
      hud_dirty = 0;
  }
  ```
- **Divide once a second, not per frame:** keep a frame counter and update `seconds = frames / 60` when a
  60-frame counter wraps.
- Debug/stress readouts: spread items over 16 frames (`(t & 15) == 0`, `== 4`, `== 8`, ...).

Layout facts:
- The window covers everything from its top line to the bottom of the screen: the HUD goes at the **bottom**
  (`move_win(7, 136)` for one row; `move_win(7, 144 - rows * 8)` for more). A top HUD has to be sprites.
- A dialog takes over the window: after `dialog_show` / `dialog_choice` returns, reprint the HUD (`hud_show()`).
- `text_clear` works on the BG only. Clear window rows by printing spaces.
- The screen is 20 columns and a dialog line is 18 characters. Plan name lengths: three 8-letter names don't fit
  side by side (CRITTER QUEST's ending had to become a list), and `NAME 100/100` is 12+ chars.
- Per-area UI colors with `text_set_colors(pal)`; restore `pal_ui_default` in `leave`.

**CPU meter** (for any scene you need to tune): scanlines used since VBlank, averaged once a second. The Emulicious
fps counter barely moves when updates are skipped (the LCD always refreshes at ~59.7 Hz), so measure this way:
```c
void meter_begin(void) { start_time = sys_time; vbls += (uint8_t)(start_time - last_time); last_time = start_time; }
void meter_end(void) {                              /* after the scene's work */
    uint8_t ly = LY_REG, lines;
    if (sys_time != start_time) lines = 154;        /* ran past the next VBlank: 100% */
    else lines = ly >= 144 ? ly - 144 : ly + 10;
    lines_acc += lines; if (lines > peak_lines) peak_lines = lines; frames++;
    if (vbls >= 60) {                               /* once per second */
        meter_avg = (uint8_t)(((uint16_t)(lines_acc / frames) * 167) >> 8);   /* lines * 100 / 154 */
        meter_fps = (uint8_t)(((uint16_t)frames * 60) / vbls);
        lines_acc = 0; frames = 0; vbls = 0; peak_lines = 0;
    }
}
```

---

### 14.7 Banking in practice (adds to docs/banking.md 10.1)

- **Const data is read only by code in its own bank.** Every mistake of this kind compiled cleanly and read
  garbage at run time. The cases met:
  - A `const body_t` passed to a function in another file: put it in RAM (`static body_t nobody = {...}` without
    `const`).
  - `particle_style_t` and the `sprite_t` it points to, used from several scenes: keep them in a **non-banked**
    `fx.c`.
  - A banked function returning a pointer to a string literal: the literal lives in that function's bank. Return
    a pointer into RAM, or 0.
  - Strings and tables passed to the engine **from the file that defines them** are fine (`dialog_show("...")`,
    `menu_run(x, y, options, n)`, `gfx_set_bkg_palette(1, pal)`): the engine reads them while that bank is mapped.
- **Read another bank's data by copying it to RAM** with a tiny non-banked helper:
  ```c
  /* src/game/romcopy.c: NOT banked (it switches the 0x4000 window) */
  void rom_copy(void *dst, const void *src, uint16_t n, uint8_t bank) {
      uint8_t save = CURRENT_BANK;
      SWITCH_ROM(bank); memcpy(dst, src, n); SWITCH_ROM(save);
  }
  ```
  A tileset in another bank goes to VRAM through a RAM buffer, 64 tiles (1 KB) at a time: `rom_copy`, then
  `set_bkg_data`.
- **Bank numbers of `-autobank` files** come from the linker: take `&__bank_<name>` (the address *is* the bank
  number) and cast it, `(uint8_t)(uint16_t)&__bank_world_r00`. Build tables of pointers and banks with an X-macro
  list, so 96 files don't mean 192 hand-written entries:
  ```c
  #define WORLD_ROWS(X) X(00) X(01) /* ... */ X(95)          /* world.h */
  #define ROW_PTR_(n)  world_r##n,
  #define ROW_BANK_(n) &__bank_world_r##n,
  static const wscreen_t * const row_ptr[WORLD_H] = { WORLD_ROWS(ROW_PTR_) };
  static const void * const row_bank[WORLD_H] = { WORLD_ROWS(ROW_BANK_) };
  ```
- **Data files that fill a bank exactly:** 128 records of 128 bytes = 16,384 bytes. Records of a power-of-two
  size also let code find a record's start from any pointer into it (`(uint16_t)p & 0xFF80` for 128-byte records
  in a 128-aligned buffer).
- **Many data files:** have them include only `<gb/gb.h>` (for `BANKREF`) and their format header, not `engine.h`,
  to avoid the 2 bytes of bank 0 each. 96 world files overflowed bank 0 by ~200 bytes this way.
- **Measuring bank 0.** Link with `-Wl-m` and check `_GSFINAL`, or sum the fixed-bank areas of each object:
  ```sh
  node -e 'const fs=require("fs");for(const f of fs.readdirSync("build/obj")){let s=0;for(const l of fs.readFileSync("build/obj/"+f,"utf8").split("\n")){const m=l.match(/^A (_CODE|_HOME|_INITIALIZER|_LIT|_GSINIT|_BASE) size ([0-9A-F]+)/);if(m)s+=parseInt(m[2],16)}if(s>2)console.log(s,f)}'
  ```
  When it grows unexpectedly, build `HEAD` in a scratch `git worktree` and diff the per-object sizes. Write the
  bytes still free in `GAME.md` after every change that touches bank 0.
- **Header guard names are macros too:** `#ifndef WORLD_H` clashed with `#define WORLD_H 96`. Use `<NAME>_FORMAT_H`
  or `<FILE>_H` names that no value macro will use.

---

### 14.8 Worlds bigger than the map module: a streamed 3×3 screen ring

Used by the RPG for a 128×96-screen world (2,560×1,728 tiles, 1.5 MB in 96 banks). It is game code
(`src/game/overworld.c` at `ba24b22`), and the scheme works for any game with more map than one bank or than
200×200 tiles.

**Data format.** A screen = 10×9 metatiles of 16×16 px = one GB screen. A record is `char map[91]` (9 rows of 10
chars + NUL) + `char name[13]` + `char sign[24]` = 128 bytes. One file per row of screens, one bank per file. The
metatile legend (`char, coll, tag, tile[4], attr[4]`) lives with the tileset.

**Ring.** The 3×3 screens around the player's screen live in WRAM (9 × 128 bytes). When the player's center enters
another screen:
- the ring re-centers, and the screens still inside keep their slots;
- the 3 that left (5 on a diagonal) are freed and the new ones are queued;
- one queued screen is loaded **per frame**, nearest first (center, edges, corners): copy 128 bytes and translate
  the 90 chars to metatile ids, ~5,000 cycles.

**Stall fallback.** Any read of a still-queued slot (a new BG column, a collision probe) loads it on the spot and
counts a stall. At 8 px per frame the queue drains in ≤ 5 frames and a new screen needs 9+ frames to scroll into
view, so it never triggers in play. To prove it works, corrupt the queued slots in the emulator: every forced load
should happen and the screen should stay exact.

**BG streaming** is the engine map module's scheme, reading from the ring:
- `update` gathers the new column or row (`id << 2 | quadrant`, then two 128-byte lookup tables for tile and
  attribute);
- the next `update` writes it first thing, while still in VBlank: rows with GDMA (2 × 32 bytes, when LY is
  144–152), columns byte by byte, split where the 32×32 BG map wraps.

**Collision** reads the metatile under each of the 4 hitbox corners, ~1,000 cycles in all: no `body_move`, no
engine map.

**RAM.** Every buffer is at a fixed address in D000–D6DF (`__at`), and `enter` rebuilds all of it (the tables, the
9 screens and a full redraw), so another scene overwriting that memory is harmless.

**Cost:** walking 17% average, 43% peak; flying 8 px per frame diagonally, 50–58% peak, 60 fps.

**Generating a big world.** The rows came from a throwaway Node generator: value-noise continent, biomes by
latitude and moisture, towns on a 6-screen spacing, roads by A* over a minimum spanning tree, bridges over water.
Golden rule 1 forbids committing it, so the output must be plain text you can edit by hand. Tell the human that
it can't be regenerated.

---

### 14.9 Writing fast, small C for SDCC (game code too)

Bank 0 is nearly full and the CPU is slow, so code size counts as much as speed. What was measured:

| Do | Why |
|---|---|
| `static` variables (file or function) instead of stack locals in hot functions | SM83 stack access is slow; `ld a,(nn)` is cheap |
| Loop helpers with **one or two pointers** and a `uint8_t` count, `do { ... } while (--n);` | SDCC keeps them in registers; three or more live pointers spill to the stack |
| Work on one static "current item": `memcpy` in, update, copy the changed bytes back | Direct addressing beats `p->field` through a struct pointer (particles: 3,900 → ~2,700 per item) |
| Read a struct as bytes in field order through a `const uint8_t *` | Compiles to `ld a,(hl+)` |
| Shift-and-add instead of `*` for small factors; tables instead of `/` and `%` | `__muluchar` ~555 cycles; a library divide ~1,000+ |
| `rand() & mask`, redrawn when above the limit, instead of `rand() % n` | Uniform and no divide |
| Percent as `(x * 167) >> 8` for `/ 154`; seconds divided once a second | One multiply, rarely |
| 8-bit tile coordinates for culling and range checks: `(uint8_t)(v - lo) <= n` | One byte compare |
| 256-byte-aligned buffers: test only the low byte of a pointer | `shadow_OAM` is aligned for OAM DMA |
| Measure before keeping a "faster" version | A fully inlined collision query was *slower* (1,178 vs 1,029): signed 16-bit compares cost more than the call |

Tried and slower: structure-of-arrays for particles, unrolled copies, 8-bit speeds with separate pixel + fraction
bytes (SDCC promotes and spills each 8-bit temporary).

SDCC/GBDK gotchas met while building games:
- Names that clash with GBDK functions: a variable called `mode` broke the build (GBDK has `mode()`). Prefix game
  globals.
- Avoid compound literals (`&(body_t){...}`); use a named `static` object.
- A `#define`d tile index passed to a `uint8_t` parameter can warn (it is an `int`): define it as
  `((uint8_t)224)`.
- `const char * const table[]` for string tables; `\f` new page and `\n` new line inside dialog text.

---

### 14.10 Checking a game without seeing the screen

The headless emulator in `tests/engine/gbc.mjs` runs the **real game ROM**, not only unit tests. Throwaway Node
drivers in the scratchpad (never committed) did all the checks behind ENGINE LAB and CRITTER QUEST:
- **Scripted joypad:** drive the real menus and gameplay.
- **Screen as text:** read the BG/window map back from VRAM and turn font tiles into characters
  (`c = tile - 128 + 32`) to check menus, dialogs and the HUD.
- **Streaming check:** compare every visible BG cell with the map data after moving. The scroll stress passed
  319,200 cell checks this way.
- **Game state:** read and write globals at their addresses from the linker's symbol output. Poke RAM only while
  the game sits in `vsync()`: writing the hero's X in the middle of `body_move` got the old value written back.
- **Wait for conditions, not frame counts** (menu on screen, scene changed): fades and blocking menus shift the
  timing, and a press made during a fade is lost or lands on the wrong menu item.
- **Frame overruns:** count frames whose update passed the next VBlank (or use the in-game meter, 14.6). This is
  how the "slow for a moment" bug was found: bursts of ~36 dropped frames in under 3 s while scrolling and
  picking up coins.
- **Pictures:** `gbc.mjs` draws no pixels. To see art, write a throwaway renderer from VRAM tiles + palettes to
  PNG, or preview `PX` grids as PNG with a Node helper before writing the asset.
- **Regression pair:** after changing RAM layout or banks, rerun the memory/ROM checks and then start the scenes
  that use fixed-address buffers.

What still needs the human in Emulicious: art, feel (speeds, jump height, encounter rate), music and SFX, flicker.
Say exactly what to look at and where the tuning constants are (file + name).

---

### 14.11 Environment and workflow lessons

- `build.sh` may lack the exec bit: run `sh build.sh`.
- GBDK-2020 lives in `~/gbdk` (the official Linux arm64 release works on a Raspberry Pi 5).
- A game with many asset banks builds slowly (each 16 KB data file compiles in ~1 s): run long builds in
  the background, and never edit files while a build that ran `git stash` is still going.
- `git stash` doesn't include untracked files: to compare with `HEAD`, build a clean `git worktree` in a scratch
  folder and remove it afterwards.
- Two sessions in one checkout collide: the unit test runner wipes `build/tests/engine/`, and one session's
  half-finished engine edit breaks the other's build. Check `git status` for files you didn't write before
  trusting a failure.
- Run `node tests/engine/run.mjs` before starting. If a test already fails on a clean `HEAD`, report it; don't
  build on top of it.
- Keep `GAME.md`'s numbers current after each change: bank 0 free, where RAM ends, CPU per scene.

---

### 14.12 Checklist: a new game (adds to CLAUDE.md 12.0 and 12.2)

- [ ] Banked or unbanked decided and written in `GAME.md`. If banked: scene table and `BANKED` headers from the
      first file (14.1, 14.3).
- [ ] Worst-case CPU of the main play scene estimated from 14.2 (≤ ~65% average), and the design cut until it fits.
- [ ] Off-screen actors frozen; slow movers at half rate; static pickups are tile coordinates + `spr_put`.
- [ ] Objects found with one map scan on load; tag bits only for flags tested per frame; one `body_touch_tags`
      per body per frame.
- [ ] Update order of 14.3: blocking UI before `cam_follow`, player drawn first, HUD last.
- [ ] HUD: labels once, one changed value per frame, no `/` or `%` per frame.
- [ ] A blocking scene skips its first update.
- [ ] Data read from another bank is in RAM or bank 0.
- [ ] Bank 0 bytes free and the end of RAM measured and written in `GAME.md`.
- [ ] Play scene profiled in the headless emulator (no bursts of dropped frames); the human told what to check in
      Emulicious.
