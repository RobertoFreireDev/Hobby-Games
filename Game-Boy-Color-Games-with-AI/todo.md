# Engine performance TODO

Measured 2026-09-27 in the headless emulator (`tests/engine/gbc.mjs`) with a throwaway benchmark suite (not committed:
engine + `unit.c`, each call timed between two serial-port marks, interrupts off). A frame at CGB double speed is
**140,448 cycles**; VBlank is ~9,100, of which ~7,300 are left after the VBL interrupt.

Every item that changes `src/engine/` needs new or updated unit tests in `tests/engine/` and an updated cost table in
`docs/debugging.md` 13.1 (CLAUDE.md rules 9 and 12).

**Bank 0 is the hard limit.** The engine, `font_main.c` and GBDK nearly fill it: every change must stay about
size-neutral, and SDCC's code for struct pointers and many locals is large as well as slow. What worked:
- statics instead of stack locals; one static "current item" (`memcpy` in and back out) instead of `p->field`
- small helper loops with one or two pointers (SDCC keeps them in registers; three or more spill to the stack)
- reading a struct as a byte pointer in field order (`ld a,(hl+)`)
- GBDK's `__muluchar` costs ~555 cycles: shift-adds are cheaper for small factors

## Status

Top 5 and the shake items are implemented; the full unit suite passed after them (203 tests), and 4 tests in
`test_map.c` / `test_scene.c` were updated for the new row writes. **Still open for them:** new tests (list below), the
docs, and a game build check of bank 0 (`sh build.sh`; `build.sh` has no exec bit here).

| Engine file | Code before | Code now (bytes) |
|---|---|---|
| `sprites.c` | 400 | 437 |
| `particles.c` | 968 | 776 |
| `tween.c` | 932 | 838 |
| `fade.c` | 404 | 481 |
| `gfx.c` | 536 | 542 |
| `map.c` | 3,209 | 3,557 |
| **Total** | 6,449 | 6,631 (+182) |

## Top 5

### 1. Sprite drawing (`src/engine/sprites.c`) — done
- [x] `spr_draw` without a call per tile: one fixed-range 16-bit reject (`sx` -96..159, `sy` -112..143), then 8-bit
      culling per tile in `draw_row`, writing `shadow_OAM` through a pointer
- [x] No `frame * s->tpf` multiply: shift-and-add, reading the `sprite_t` as bytes in order
- [x] `spr_put` cheaper (pointer writes); `spr_end` / `spr_hide_all` share one loop
- [x] The 40-entry limit is checked on the low byte of the OAM pointer (`shadow_OAM` is 256-byte aligned for OAM DMA)

| Call | Before | Now |
|---|---|---|
| `spr_put` | 806 | 556 |
| `spr_draw` 1x1 | 2,547 | 1,636 |
| `spr_draw` 2x2 | 5,964 | 2,588 |
| `spr_draw` 2x2 FLIPX | — | 2,712 |
| `spr_draw` 3x2 | — | 3,108 |
| `spr_end` hiding 40 | 4,352 | 2,596 |

~240 cycles per extra tile; the rest is per-call overhead SDCC won't shrink further in C.
New limit: sprites up to 11x12 tiles (document in `docs/engine-api.md` 7.4). OAM order within a FLIPX sprite is unchanged.

### 2. Particles (`src/engine/particles.c`) — done
- [x] `particles_emit` copies tile, palette, gravity, frame data into the particle; styles are read only at emit time
- [x] OAM written directly (`spr_next` is now `extern` in `sprites.h`, engine internal)
- [x] `rand_vel`: masked random byte, redrawn when above `2 * speed` (uniform, no multiply). `speed` must be 0-127
- [x] One static working particle copied in / back out (only the 10 changing bytes go back)

| Call | Before | Now |
|---|---|---|
| `particles_update`, 12 alive | 42,240 | 32,600 |
| `particles_update`, 0 alive | 4,492 | 2,312 |
| `particles_emit`, 12 | 39,936 | 26,424 |

`memcpy` is ~40% of the update (~1,070 per particle). Tried and slower: struct pointer, byte walk, structure of
arrays, 8-bit speeds with pixel + fraction positions (SDCC spills every 8-bit temporary).

### 3. Camera streaming (`src/engine/map.c`) — done
- [x] `draw_row` / `draw_col`: copy the map chars, then translate in place with `xlat_tile` / `xlat_attr` (~64 cycles per
      cell and table)
- [x] Rows gathered into a 32-byte buffer laid out like the BG map (`ROW_BUF`, 32-aligned inside `row_mem`), copied with
      GDMA when LY is 144-152, byte by byte with HBlank waits otherwise
- [x] `map_flush` fits in VBlank for a row or a column; a diagonal is just under

| Case | Gather before | Gather now | Write before | Write now |
|---|---|---|---|---|
| Idle | 2,457 | 2,368 | 216 | 216 |
| New column | 15,616 | 12,748 | 8,192 | 5,892 |
| New row | 13,312 | 10,820 | 7,424 | 976 |
| Diagonal | 26,624 | 21,200 | 18,688 | 6,652 |

Behavior change: a row write now fills all 32 cells of the BG map row; the 11 outside the drawn 21x19 area get
leftover tiles (never visible: a column is drawn whole before it scrolls in, and the shake stays inside the drawn cells).
Document in `docs/engine-api.md` 7.6.

### 4. Tweens (`src/engine/tween.c`) — done
- [x] Step computed once in `tween_start` (one `0xFFFF / frames`), progress accumulated in 16 bits
- [x] Ease tables are bytes (256 stored as 0; the byte subtraction wraps to the right rise); interpolation by shift-adds
      (`mul4`), value by `scale`: one `__muluchar` for moves under 256 px, two above
- [x] Running tweens in a bitmask: free slots cost nothing, 0 active returns at once

| Case | Before | Now |
|---|---|---|
| 0 active | 2,918 | 192 |
| 1 active | 12,480 | 3,388 |
| 4 active (1000 px moves) | 40,960 | 12,988 |
| 4 active (100 px moves) | — | 11,020 |
| `tween_start` | 3,816 | 7,092 (the division moved here) |

### 5. Palette changes (`src/engine/gfx.c`, `src/engine/fade.c`) — done
- [x] `gfx_set_*_palette` → `fade_apply_colors(i, 4)`: converts and writes only the 4 changed colors; at level 0 it
      uploads `pal_ram` directly (no conversion, no LUT build)
- [x] Own palette upload: one STAT check per color (palette RAM is locked only in mode 3; after mode 0/1 at least the
      80 dots of mode 2 remain)
- [x] Fades: `fade_step` converts before `vsync()` and only uploads after it, inside VBlank
- [x] Color conversion in bytes (`lo = gggrrrrr`, `hi = 0bbbbbgg`), no 16-bit shifts

| Call | Before | Now |
|---|---|---|
| `fade_apply` at level 0 | ~24,000–90,000 (depends on where in the frame) | 7,084 |
| `fade_set_level(3)` (converts 64 colors) | ~91,000 | 56,276 |
| `gfx_set_obj_palette`, level 0 | 26,291–91,944 | 1,836 |
| `gfx_set_obj_palette`, level 4 | — | 4,364 |

Converting 64 colors is still ~770 cycles per color; it runs before `vsync()` in fades, so it no longer tears.

## Still to do for the Top 5

### Tests (`tests/engine/`)
- [ ] `test_sprites.c`: `shadow_OAM` is 256-byte aligned; clipping at the right / bottom edges; FLIPY with the top row
      off screen; far-off positions (-96, -97, 160, ±32767) draw nothing; OAM full in the middle of a sprite; frame
      numbers above 3 (shift-and-add); `spr_hide_all` resets and hides 40
- [ ] `test_particles.c`: `speed` 127 stays in range; `up` + speed; particles fill OAM up to 40 with other sprites drawn first
- [ ] `test_tween.c`: moves over 256 px in both directions (two multiplies), all four eases at every step against the
      old formula, restarting a running tween keeps the bitmask right, 8 tweens finishing together
- [ ] `test_fade.c` / `test_gfx.c`: `gfx_set_*_palette` at a non-zero level writes only its palette; `fade_apply_colors`;
      a fade step's colors are written inside VBlank (LY 144-153 when the upload ends)
- [ ] `test_map.c`: `map_flush` right after `vsync()` (GDMA path) gives the same screen as outside VBlank; a row that
      wraps the BG map; `map_set_tile` patches a pending row at the wrap; shake never shows a column / row outside the
      drawn cells (check SCX/SCY against `cam_x & 7`), never scrolls left of / above the map, strength clamped to 7

### Docs
- [ ] `docs/engine-api.md`: code listings of 7.4 (sprites), 7.6 (streaming, shake), 7.10 (fade, `fade_apply_colors`),
      7.11 (tween tables), 7.12 (particles: speed 0-127, styles read only by `particles_emit`); `spr_next`
- [ ] `docs/debugging.md` 13.1: new cost table, and fix the `text_print_num` line (see below)
- [ ] `docs/banking.md` 10.1: `particle_style_t` is read by `particles_emit` only (still bank 0 when emitted from several banks)
- [ ] `src/game/fx.h` comment: same reason

## Next in line
- [ ] `body_move` 9,968 per 10x14 body (the tile-flag rework is committed now)
- [ ] `text_print_num_win` 11,124 even in VBlank: two `set_win_tile_xy` calls per character, not HBlank waits as
      `docs/debugging.md` 13.1 says. Write the window map directly (attributes pass, then tiles pass, like `vram_row`)
- [ ] `text_print_num` 13,592: same fix on the BG map (with the & 31 wrap)
- [ ] `anim_update` 984 per entity (SDCC keeps reloading `a->def`)
- [ ] `fade_set_level` / fade steps: color conversion ~770 per color

## Bug found along the way
- [x] Camera shake showed stale tiles on the left and top edges (a negative offset revealed the column / row before
      `drawn_tx` / `drawn_ty`) and wrapped to the far side of the BG map at the map's edge. Now `shake_off` keeps the
      offset in `-(cam & 7) .. 8 - (cam & 7)`, mirrored first so it still moves both ways. Shake costs 3,672 per frame
      (was 7,992: the two `rand() %` are gone, one random byte gives both axes)

## Other measurements (for reference, unchanged code)

| Call | Cycles |
|---|---|
| `map_char` | 392 |
| `map_coll_px` | 924 |
| `body_touch_tags` 10x14 | 4,044 |
| `body_on_ground` | 2,776 |
| `map_set_tile` | 1,684 |
| `cam_set` | ~442,000 (scene start, screen black) |
