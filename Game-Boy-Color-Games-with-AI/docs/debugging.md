# Debugging and troubleshooting

Read when: a build fails, or something looks or sounds wrong in the emulator.

## 13. Debugging and troubleshooting

- `EMU_printf("x=%d y=%d", x, y);` (from `<gbdk/emu_debug.h>`) prints to Emulicious's debug console; remove it for release.
- Emulicious: *Tools → Tile Viewer / Palette Viewer / Tilemap Viewer / Sprite Viewer* shows exactly what is in VRAM.

| Symptom | Likely cause |
|---|---|
| Garbage tiles | `PX` row count wrong, wrong tile index, loaded to the wrong VRAM bank (`VBK_REG` left at 1) |
| Wrong colors on BG | Attribute palette not set (bank 1 write missing) or palette slot not loaded |
| Sprites flicker/disappear | More than 10 sprites on a line or more than 40 total |
| Text shows as blocks | Font not loaded in bank 1, or attribute bit 3 missing |
| Screen white flash | `DISPLAY_OFF` used outside `engine_init` |
| Music drifts out of sync | Channel loop lengths differ |
| Slowdown | Heavy math per frame, too many entities, `%`/`/` in loops, full-screen redraws every frame, text printed every frame (13.1) |
| Crash after adding data | ROM overflow into bank switching problems → section 10, [banking.md](banking.md) |
| `?ASlink-Warning-Undefined Global` | Missing `.c` file, typo, or declared in `assets.h` but never defined |
| Build error "multiple definition" | Two `.c` files with the same base name, data defined in a header, or `sfx_menu` defined outside `font_main.c` |
| Link error undefined `_scene_title` | Template with no game yet: write `src/scenes/title.c` (example in `src/scenes/file.txt`) |

### 13.1 Performance budget

A frame at CGB double speed is **140,448 CPU cycles**. Costs per call, measured with the ENGINE LAB stress
cart in the headless emulator (`tests/engine/gbc.mjs`), inclusive of everything the call does:

| Call | Cycles |
|---|---|
| `map_char` / `map_coll` / `map_coll_px` | ~450 / ~600 / ~950 |
| `map_coll_rect` / `map_tag_rect` | ~1,900 for one cell, +~180 per extra cell in a row, +~800 per extra row |
| `body_move` (8x8 to 10x14 body) | ~10,000-10,500 |
| `body_on_ground` (10 px wide) | ~2,700 |
| `body_touch_tags` (8x8 or 10x14: 2x2 cells) | ~4,000 |
| `map_find` / `map_find_tag` | ~120 per cell scanned |
| `spr_put` / `spr_draw` 1x1 / `spr_draw` 2x2 | ~600 / ~2,500 / ~5,900 |
| `tween_update` | ~10,000 per active tween |
| `particles_update` / `particles_emit` | ~3,600 / ~3,100 per particle |
| Camera streaming (`cam_follow` crossing a tile) | ~13,000 per new column or row, + ~9,000 in `map_flush` (VBlank) |
| `text_print_num` / `text_print_num_win` (5 digits) | ~13,000 (~2,500 per character: VRAM writes wait for HBlank) |
| `rect_overlap` called from banked code / `body_overlap` | ~6,000 / ~1,250 |

So one frame holds roughly 5-6 colliding bodies, **or** ~20 moving 1x1 sprites, **or** the full pool of 12
particles (~45,000), **or** ~12 tweens, on top of the player. A scene whose average is already ~80% drops a frame
whenever one-off costs stack up (a pickup that emits particles and reprints the HUD while the camera streams a
line); several such frames close together feel like a short slowdown. Rules that keep a scene at 60 fps:
- Freeze and skip drawing off-screen entities; run slow movers' physics every other frame (alternate halves).
- Cull in 8-bit tile units before 16-bit math; draw 1x1 sprites with `spr_put` instead of `spr_draw`.
- Pre-check cheap distances before `rect_overlap` / `body_overlap`.
- Scan the map once on load and keep coordinates: `map_find` / `map_find_tag` rescan from the top on every
  call (a 120x24 map is ~2.5 frames per full scan).
- Test tile flags as byte tags: give only the flags checked while playing a `TAG_*` bit and test them all with
  one `body_touch_tags` per body per frame, not one query per flag or per cell.
- Print text only when a value changes, one item per frame, labels once.
- Avoid `%` and `/` (library calls, ~1,000+ cycles) in anything that runs per frame or per entity.
- Let `scene_update` write the camera's streamed lines (`map_flush`, engine-api.md 7.6): a loop with its own
  `vsync()` that moves the camera calls `map_flush()` right after it.
- Compiler flags don't help: `--max-allocs-per-node50000` changed these numbers by under 1%.
