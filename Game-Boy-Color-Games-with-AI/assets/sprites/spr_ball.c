#pragma bank 255
#include "engine/engine.h"
/* 8x8 ball for the stress tests (stress scenes recolor it with OBJ slots 3-5) */
BANKREF(spr_ball)

/* 0 transparent, 1 outline, 2 pink, 3 shine */
static const palette_color_t pal[4] = { RGB8(0,0,0), RGB8(40,24,72), RGB8(224,72,120), RGB8(255,216,232) };

static const uint8_t tiles[] = {
    /* frame 0 (ball), tile 0 */
    PX(0,0,1,1,1,1,0,0),
    PX(0,1,2,2,3,3,1,0),
    PX(1,2,2,2,2,3,3,1),
    PX(1,2,2,2,2,2,3,1),
    PX(1,2,2,2,2,2,2,1),
    PX(1,2,2,2,2,2,2,1),
    PX(0,1,2,2,2,2,1,0),
    PX(0,0,1,1,1,1,0,0),
};

const sprite_def_t spr_ball = { tiles, 1, 1, 1, pal, 3 };   /* w, h, frames, pal, OBJ slot 3 */
