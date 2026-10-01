#ifndef OVERWORLD_H
#define OVERWORLD_H
#include "engine/engine.h"

/* PLAY GAME 2 overworld streaming (src/game/overworld.c). The world (assets/world/) is 128x96 screens of 10x9
   metatiles, one ROM bank per row of screens. A 3x3 ring of screens around the player's screen lives in WRAM:
   when the player crosses into another screen, the ring re-centers on it, the 3 (or 5, diagonally) screens that
   left it are dropped and the new ones are loaded one per frame. A cell read from a screen that isn't loaded
   yet loads it on the spot (a "stall"): it only happens when the player crosses two screens faster than the
   queue loads (5 frames at most).
   The BG map is streamed from the ring like the engine's map module (7.6): ow_update gathers new rows/columns,
   ow_flush writes them in VBlank. The engine's map module is not used (its maps are at most 200x200 tiles). */

#define OW_VIEW_H 136                       /* visible BG height: the HUD window covers the last row */

extern int16_t ow_cam_x, ow_cam_y;          /* world px of the screen's top-left */
extern uint16_t ow_loads, ow_stalls;        /* screens copied from ROM; loads forced by a read */
extern uint8_t ow_sx, ow_sy;                /* the player's screen = center of the ring */

void ow_init(uint16_t px, uint16_t py) BANKED;     /* scene start (screen faded out): tileset, palettes, the 9
                                                      screens around world px (px, py), full redraw centered on it */
void ow_flush(void) BANKED;                         /* first thing in update, in VBlank: pending row/column + scroll */
void ow_update(uint16_t px, uint16_t py) BANKED;    /* after moving: re-center the ring, camera, stream, load one */

/* OR of the COLL_* bits of the cells at the 4 corners of a rect (x0 <= x1, y0 <= y1, at most 16 px each way) */
uint8_t ow_coll(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1) BANKED;
uint8_t ow_tag(uint16_t x, uint16_t y) BANKED;              /* TAG_* of the cell at world px */
const char *ow_sign(uint16_t x, uint16_t y) BANKED;         /* sign text of the screen holding that cell (RAM), 0 if none */
const char *ow_name(void) BANKED;                           /* area name of the player's screen (RAM) */
uint8_t ow_bank(void) BANKED;                               /* ROM bank of the player's row of screens */
#endif
