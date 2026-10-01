#pragma bank 255
#include "engine/engine.h"
/* 8x8 coin, 3 frames of a spin: face, turning, edge */
BANKREF(spr_coin)

/* 0 transparent, 1 outline, 2 gold, 3 shine */
static const palette_color_t pal[4] = { RGB8(0,0,0), RGB8(120,64,0), RGB8(248,192,40), RGB8(255,248,184) };

static const uint8_t tiles[] = {
    /* frame 0 (face), tile 0 */
    PX(0,0,1,1,1,1,0,0),
    PX(0,1,2,3,3,2,1,0),
    PX(1,2,3,2,2,2,2,1),
    PX(1,2,3,2,2,2,2,1),
    PX(1,2,2,2,2,2,2,1),
    PX(1,2,2,2,2,2,2,1),
    PX(0,1,2,2,2,2,1,0),
    PX(0,0,1,1,1,1,0,0),
    /* frame 1 (turn), tile 0 */
    PX(0,0,0,1,1,0,0,0),
    PX(0,0,1,3,3,1,0,0),
    PX(0,0,1,3,2,1,0,0),
    PX(0,0,1,3,2,1,0,0),
    PX(0,0,1,2,2,1,0,0),
    PX(0,0,1,2,2,1,0,0),
    PX(0,0,1,2,2,1,0,0),
    PX(0,0,0,1,1,0,0,0),
    /* frame 2 (edge), tile 0 */
    PX(0,0,0,1,1,0,0,0),
    PX(0,0,0,1,3,0,0,0),
    PX(0,0,0,1,3,0,0,0),
    PX(0,0,0,1,3,0,0,0),
    PX(0,0,0,1,3,0,0,0),
    PX(0,0,0,1,3,0,0,0),
    PX(0,0,0,1,3,0,0,0),
    PX(0,0,0,1,1,0,0,0),
};

const sprite_def_t spr_coin = { tiles, 1, 1, 3, pal, 2 };   /* w, h, frames, pal, OBJ slot 2 */
