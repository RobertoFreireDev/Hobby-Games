# ROM banking

Read when: the linker reports ROM/area overflow (non-banked code + data past 32 KB), or a game banks any data.

## 10. ROM banking (only when the game grows past 32 KB)

While nothing is banked, non-banked code and data may fill 0x0000-0x7FFF (32 KB). As soon as anything is
banked, every `SWITCH_ROM` replaces 0x4000-0x7FFF, so **all non-banked code and data must fit in bank 0
(0x0000-0x3FFF, 16 KB)**. The engine, `font_main.c` and the GBDK library already use about **14.7 KB** of it,
leaving roughly 1.6 KB for the game. So a banked game banks its own code too (10.1).

The linker prints an error about ROM/area overflow when non-banked code+data exceed 32 KB. Then:
1. Keep **the engine, music, SFX and font non-banked**.
2. Move large **maps, tilesets and sprite data** to banked files: add `#pragma bank 255` as the first line and `BANKREF(name)` for the main struct; in `assets.h` use `BANKREF_EXTERN(name)`.
3. Everything a load call touches must be **in the same banked file** (a map file includes its own tileset rows/tiles/palettes; a sprite file its tiles and palette).
4. Load with the bank: `map_load(&map_level5, BANK(map_level5));` `gfx_load_sprite(&h, &spr_boss, BANK(spr_boss));`
5. Engine loaders switch and restore: `uint8_t save = CURRENT_BANK; if (bank) SWITCH_ROM(bank); ... if (bank) SWITCH_ROM(save);`. The map module stores the bank and switches in `map_char` and while streaming.

Check bank 0 after adding code or data: link with `-Wl-m` and make sure the last bank-0 area (`_GSFINAL` in the
`.map`) ends below `0x4000`.

Every file that includes `engine/engine.h` also costs **2 bytes of bank 0 and 2 of RAM**: GBDK's `gbdk/emu_debug.h`
defines an initialized static pointer in each one. That is nothing for normal files, but a game with dozens of banked
data files (ENGINE LAB's 96 world rows, `assets/world/`) overflowed bank 0: such files include only `<gb/gb.h>` (for
`BANKREF`) and their own format header.

### 10.1 Banked game code (worked example: ENGINE LAB, `src/scenes/scene_table.c`)

- Game files start with `#pragma bank 255`; every function called from another file is declared `BANKED` in its
  header (`void player_init(uint16_t tx, uint16_t ty) BANKED;`). Calls between banks go through GBDK's trampoline.
- The scene manager calls `scene_t` members through plain function pointers, which can't reach a switchable bank.
  Keep the `scene_t` structs in one **non-banked** file with tiny stubs:
  ```c
  static void level_e(void) { level_enter(); }    /* level_enter is BANKED, in src/scenes/level.c */
  static void level_u(void) { level_update(); }
  const scene_t scene_level = { level_e, level_u, 0 };
  ```
- **Const data is read only by code in its own bank**, or by an engine loader given `BANK(x)`. Static functions,
  string literals and `const` tables of a banked file live in that file's bank, so passing them to the engine
  from that file is fine (`dialog_show("...")`, `menu_run(x, y, options, n)`, `gfx_set_bkg_palette(1, pal)`).
- Data read by code in **another** bank goes in RAM or bank 0. Typical cases: a `const body_t` passed to another
  file's function, `particle_style_t` (read every frame by `particles_update`, whatever bank calls it),
  `anim_def_t` read with `anim_frame()` outside the file that defines it.
- Code that switches the 0x4000-0x7FFF window itself (reading a banked table byte by byte) must be **non-banked**,
  or it unmaps itself.
- `CURRENT_BANK` is the caller's bank inside a banked function, so the engine loaders' save/restore keeps working.
