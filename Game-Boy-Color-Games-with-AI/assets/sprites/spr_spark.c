#pragma bank 255
#include "engine/engine.h"
/* 8x8 particle, 3 frames shrinking over its lifetime */
BANKREF(spr_spark)

/* 0 transparent, 1 orange, 2 yellow, 3 white */
static const palette_color_t pal[4] = { RGB8(0,0,0), RGB8(232,112,32), RGB8(248,224,80), RGB8(255,255,232) };

static const uint8_t tiles[] = {
    /* frame 0 (big), tile 0 */
    PX(0,0,0,1,0,0,0,0),
    PX(0,0,1,2,1,0,0,0),
    PX(0,1,2,3,2,1,0,0),
    PX(1,2,3,3,3,2,1,0),
    PX(0,1,2,3,2,1,0,0),
    PX(0,0,1,2,1,0,0,0),
    PX(0,0,0,1,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    /* frame 1 (mid), tile 0 */
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,1,0,0,0,0),
    PX(0,0,1,2,1,0,0,0),
    PX(0,1,2,3,2,1,0,0),
    PX(0,0,1,2,1,0,0,0),
    PX(0,0,0,1,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    /* frame 2 (small), tile 0 */
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,2,0,0,0,0),
    PX(0,0,2,3,2,0,0,0),
    PX(0,0,0,2,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
    PX(0,0,0,0,0,0,0,0),
};

const sprite_def_t spr_spark = { tiles, 1, 1, 3, pal, 6 };   /* w, h, frames, pal, OBJ slot 6 */
