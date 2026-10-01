#pragma bank 255
#include "engine/engine.h"
/* 16x8 slime enemy, 2 frames: up, squashed */
BANKREF(spr_slime)

/* 0 transparent, 1 outline, 2 green, 3 shine */
static const palette_color_t pal[4] = { RGB8(0,0,0), RGB8(16,56,24), RGB8(80,200,72), RGB8(208,248,168) };

static const uint8_t tiles[] = {
    /* frame 0 (up), tile 0 */
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,1,1),
    PX(0,0,0,0,1,1,2,2),
    PX(0,0,0,1,2,3,3,2),
    PX(0,0,1,2,3,2,2,2),
    PX(0,0,1,2,2,2,2,2),
    PX(0,1,2,2,2,2,2,2),
    PX(0,1,1,1,1,1,1,1),
    /* frame 0 (up), tile 1 */
    PX(0,0,0,0,0,0,0,0),
    PX(1,1,0,0,0,0,0,0),
    PX(2,2,1,1,0,0,0,0),
    PX(2,2,2,2,1,0,0,0),
    PX(1,2,1,2,2,1,0,0),
    PX(1,2,1,2,2,1,0,0),
    PX(2,2,2,2,2,2,1,0),
    PX(1,1,1,1,1,1,1,0),
    /* frame 1 (squash), tile 0 */
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,1,1,1,1),
    PX(0,0,1,1,3,3,2,2),
    PX(0,1,2,3,2,2,2,2),
    PX(1,2,2,2,2,2,2,2),
    PX(1,1,1,1,1,1,1,1),
    /* frame 1 (squash), tile 1 */
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(1,1,1,1,0,0,0,0),
    PX(1,2,1,2,1,1,0,0),
    PX(2,1,2,1,2,2,1,0),
    PX(2,2,2,2,2,2,2,1),
    PX(1,1,1,1,1,1,1,1),
};

const sprite_def_t spr_slime = { tiles, 2, 1, 2, pal, 1 };   /* w, h, frames, pal, OBJ slot 1 */
