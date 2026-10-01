#ifndef ASSETS_H
#define ASSETS_H
#include "engine/engine.h"

/* Add one extern line for EVERY asset the game defines (see docs/graphics.md 6.9). */
/* Banked assets (#pragma bank 255) are loaded with BANK(name): bank 0 is full with the engine (GAME.md). */

/* palettes: each sprite / map file holds its own */

/* sprites (banked) */
BANKREF_EXTERN(spr_hero)
BANKREF_EXTERN(spr_slime)
BANKREF_EXTERN(spr_coin)
BANKREF_EXTERN(spr_spark)
BANKREF_EXTERN(spr_ball)
extern const sprite_def_t spr_hero, spr_slime, spr_coin, spr_spark, spr_ball;

/* map legend tags: game-defined bits (GAME.md -> Tile flags), read with body_touch_tags / map_tag */
#define TAG_HAZARD 0x01          /* HAZARD: spikes, lava */
#define TAG_SIGN   0x02          /* TRIGGER0: UP reads it */
#define TAG_TROPHY 0x04          /* TRIGGER1: wins */
#define TAG_CHECK  0x08          /* TRIGGER2: checkpoint */
#define TAG_DOOR   0x10          /* LEAVE0: UP goes to the other area */

/* tilesets + maps (banked; each map file includes its tileset) */
BANKREF_EXTERN(map_title)
BANKREF_EXTERN(map_level)
BANKREF_EXTERN(map_cave)
BANKREF_EXTERN(map_arena)
BANKREF_EXTERN(map_scroll)
extern const map_def_t map_title, map_level, map_cave, map_arena, map_scroll;

/* ROM stress data (banked, one bank each; format in assets/romtest/rom_blob.h) */
BANKREF_EXTERN(rom_blob_01) BANKREF_EXTERN(rom_blob_02) BANKREF_EXTERN(rom_blob_03) BANKREF_EXTERN(rom_blob_04)
BANKREF_EXTERN(rom_blob_05) BANKREF_EXTERN(rom_blob_06) BANKREF_EXTERN(rom_blob_07) BANKREF_EXTERN(rom_blob_08)
BANKREF_EXTERN(rom_blob_09) BANKREF_EXTERN(rom_blob_10) BANKREF_EXTERN(rom_blob_11) BANKREF_EXTERN(rom_blob_12)
BANKREF_EXTERN(rom_blob_13) BANKREF_EXTERN(rom_blob_14) BANKREF_EXTERN(rom_blob_15) BANKREF_EXTERN(rom_blob_16)
BANKREF_EXTERN(rom_blob_17) BANKREF_EXTERN(rom_blob_18) BANKREF_EXTERN(rom_blob_19) BANKREF_EXTERN(rom_blob_20)
BANKREF_EXTERN(rom_blob_21) BANKREF_EXTERN(rom_blob_22) BANKREF_EXTERN(rom_blob_23) BANKREF_EXTERN(rom_blob_24)
extern const uint8_t rom_blob_01[], rom_blob_02[], rom_blob_03[], rom_blob_04[], rom_blob_05[], rom_blob_06[],
                     rom_blob_07[], rom_blob_08[], rom_blob_09[], rom_blob_10[], rom_blob_11[], rom_blob_12[],
                     rom_blob_13[], rom_blob_14[], rom_blob_15[], rom_blob_16[], rom_blob_17[], rom_blob_18[],
                     rom_blob_19[], rom_blob_20[], rom_blob_21[], rom_blob_22[], rom_blob_23[], rom_blob_24[];

/* PLAY GAME 2 overworld (banked; format in assets/world/world.h). The tileset file is read with rom_copy
   (src/game/romcopy.c), each world row fills one bank and is streamed by src/game/world.c */
#include "world/world.h"
BANKREF_EXTERN(ts_overworld)
extern const uint8_t ts_overworld_tiles[];
extern const palette_color_t ts_overworld_pals[];
extern const ow_metatile_t ow_metatiles[];
BANKREF_EXTERN(spr_rpg_hero)
extern const sprite_def_t spr_rpg_hero;
#define WORLD_EXTERN_(n) BANKREF_EXTERN(world_r##n) extern const wscreen_t world_r##n[WORLD_W];
WORLD_ROWS(WORLD_EXTERN_)

/* font + engine UI (assets/fonts/font_main.c, shared by every game) */
extern const uint8_t font_main[], font_box_tiles[];

/* music (never banked) */
extern const song_t mus_title, mus_level, mus_cave, mus_win, mus_over;

/* sfx (sfx_menu lives in font_main.c: the engine's dialogs and menus use it) */
extern const sfx_t sfx_menu;
extern const sfx_t sfx_jump, sfx_coin, sfx_hurt, sfx_bump, sfx_spring, sfx_flag, sfx_stomp, sfx_boom;
#endif
