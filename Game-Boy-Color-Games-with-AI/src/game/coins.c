#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "coins.h"
#include "fx.h"

sprite_t coin_spr;
static uint8_t coin_tx[MAX_COINS], coin_ty[MAX_COINS];
static uint8_t coin_live[MAX_COINS];    /* copy of the mask as bytes: no 32-bit shifts per coin per frame */
static uint8_t coin_n;
static uint32_t *coin_taken;
static anim_t coin_anim;            /* one animation shared by every coin */
static int16_t pop_x, pop_y;        /* pop_y is driven by a tween */

static const uint8_t spin_frames[] = { 0, 1, 2, 1 };
static const anim_def_t anim_spin = { spin_frames, 4, 8, 1 };

void coins_clear(uint32_t *taken) BANKED {
    coin_n = 0;
    coin_taken = taken;
    coin_anim.def = 0;
    anim_play(&coin_anim, &anim_spin);
}

void coins_add(uint16_t tx, uint16_t ty) BANKED {
    if (coin_n >= MAX_COINS) return;
    coin_tx[coin_n] = (uint8_t)tx;
    coin_ty[coin_n] = (uint8_t)ty;
    coin_live[coin_n] = !(*coin_taken & ((uint32_t)1 << coin_n));
    coin_n++;
}

void coins_pop(int16_t wx, int16_t wy) BANKED {
    pop_x = wx;
    pop_y = wy;
    tween_start(&pop_y, wy - 20, 24, EASE_OUT);
}

uint8_t coins_update(const body_t *b) BANKED {
    uint8_t i, got = 0, tile, ctx, cty, htx, hty;
    int16_t wx, wy, sx, sy;
    anim_update(&coin_anim);
    tile = coin_spr.base + anim_frame(&coin_anim);          /* 1x1 sprite: spr_put, not spr_draw */
    if (tween_busy(&pop_y)) spr_put(coin_spr.base, W2S_X(pop_x), W2S_Y(pop_y), coin_spr.pal);
    ctx = (uint8_t)((uint16_t)cam_x >> 3);                  /* cull in 8-bit tile units first: cheap */
    cty = (uint8_t)((uint16_t)cam_y >> 3);
    htx = (uint8_t)((uint16_t)UNFIX(b->x) >> 3);             /* rect_overlap (~6K cycles) only near the body */
    hty = (uint8_t)((uint16_t)UNFIX(b->y) >> 3);
    for (i = 0; i < coin_n; i++) {
        if (!coin_live[i] || (uint8_t)(coin_tx[i] - ctx + 1) > 21 || (uint8_t)(coin_ty[i] - cty + 1) > 19) continue;
        wx = (int16_t)coin_tx[i] << 3;
        sx = W2S_X(wx);
        if (sx <= -8 || sx >= 160) continue;                /* off screen: the hero (always on screen) can't reach it */
        wy = (int16_t)coin_ty[i] << 3;
        sy = W2S_Y(wy);
        if (sy <= -8 || sy >= 144) continue;
        if ((uint8_t)(coin_tx[i] - htx + 1) <= 3 && (uint8_t)(coin_ty[i] - hty + 1) <= 3 &&
            rect_overlap(UNFIX(b->x), UNFIX(b->y), b->w, b->h, wx + 1, wy + 1, 6, 6)) {
            coin_live[i] = 0;
            *coin_taken |= (uint32_t)1 << i;
            got++;
            particles_emit(wx + 1, wy, 5, &fx_burst);
            continue;
        }
        spr_put(tile, sx, sy, coin_spr.pal);
    }
    return got;
}
