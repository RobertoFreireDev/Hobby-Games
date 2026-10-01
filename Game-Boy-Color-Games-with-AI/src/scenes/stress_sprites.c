#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/fx.h"
#include "game/meter.h"

/* Sprite stress: up to 64 balls through spr_put (the engine keeps the first 40 per frame).
   Modes: BOUNCE (free), LINE (all on one scanline: the hardware shows only 10 per line), RAIN.
   FLICKER rotates the draw order every frame, so balls past the limits flicker instead of vanishing.
   UP/DOWN +-1 ball, LEFT/RIGHT +-8, A mode, B flicker, SELECT particle burst, START back. */

#define MAX_BALLS 64
static int16_t bx[MAX_BALLS], by[MAX_BALLS];     /* fixed 12.4, screen pixels */
static int8_t bvx[MAX_BALLS], bvy[MAX_BALLS];
static uint8_t bpal[MAX_BALLS];
static uint8_t count, ball_mode, flicker, start, shown, t;
static sprite_t ball;

static const palette_color_t pal_ball_b[4] = { RGB8(0,0,0), RGB8(16,32,80), RGB8(72,152,248), RGB8(208,240,255) };
static const palette_color_t pal_ball_c[4] = { RGB8(0,0,0), RGB8(24,64,16), RGB8(136,216,56), RGB8(232,255,200) };
static const char * const mode_names[] = { "BOUNCE", "LINE  ", "RAIN  " };

static int8_t rand_speed(void) {
    int8_t v = (int8_t)((rand() & 31) + 8);
    return (rand() & 1) ? -v : v;
}

void sprites_enter(void) BANKED {
    uint8_t i, p = 3;
    gfx_load_sprite(&ball, &spr_ball, BANK(spr_ball));     /* OBJ slot 3 */
    gfx_load_sprite(&fx_spark, &spr_spark, BANK(spr_spark));
    gfx_set_obj_palette(4, pal_ball_b);
    gfx_set_obj_palette(5, pal_ball_c);
    for (i = 0; i < MAX_BALLS; i++) {
        bx[i] = FIX(8 + (rand() & 127));
        by[i] = FIX(24 + (rand() & 63) + (rand() & 31));
        bvx[i] = rand_speed();
        bvy[i] = rand_speed();
        bpal[i] = p;
        if (++p > 5) p = 3;
    }
    count = 16; ball_mode = 0; flicker = 0; start = 0; t = 0;
    text_print(0, 0, "BALLS    SHOWN");
    text_print(0, 16, "A MODE    B FLICKER");
    text_print(0, 17, "SEL FX  UD+-1 LR+-8");
    meter_labels(0, 1, 0);
    meter_reset();
}

void sprites_update(void) BANKED {
    uint8_t i, k, lx;
    int16_t *px, *py;

    meter_begin();
    if (KEY_PRESSED(J_UP) && count < MAX_BALLS) count++;
    if (KEY_PRESSED(J_DOWN) && count > 1) count--;
    if (KEY_PRESSED(J_RIGHT)) count = count + 8 > MAX_BALLS ? MAX_BALLS : count + 8;
    if (KEY_PRESSED(J_LEFT)) count = count > 8 ? count - 8 : 1;
    if (KEY_PRESSED(J_A)) ball_mode = ball_mode == 2 ? 0 : ball_mode + 1;
    if (KEY_PRESSED(J_B)) flicker ^= 1;
    if (KEY_PRESSED(J_SELECT)) { particles_emit(76, 72, 8, &fx_burst); sfx_play(&sfx_stomp); }
    if (KEY_PRESSED(J_START)) scene_goto(&scene_menu, TRANS_FADE_BLACK);

    /* move */
    lx = 4;
    for (i = 0; i < count; i++) {
        px = &bx[i]; py = &by[i];
        if (ball_mode == 0) {
            *px += bvx[i];
            if (*px < 0 || *px > FIX(152)) { bvx[i] = -bvx[i]; *px += bvx[i]; }
            *py += bvy[i];
            if (*py < FIX(16) || *py > FIX(128)) { bvy[i] = -bvy[i]; *py += bvy[i]; }
        } else if (ball_mode == 1) {
            *px = FIX(lx); *py = FIX(80);
            lx += 9; if (lx > 152) lx -= 148;
        } else {
            *py += ABS(bvy[i]) + 8;
            if (*py > FIX(144)) *py = FIX(16);
        }
    }

    /* draw: the first 40 spr_put calls get an OAM entry; flicker rotates who is first */
    shown = 0;
    if (start >= count) start = 0;
    i = start;
    for (k = 0; k < count; k++) {
        shown += spr_put(ball.base, UNFIX(bx[i]), UNFIX(by[i]), bpal[i]);
        if (++i >= count) i = 0;
    }
    if (flicker) { start += 13; while (start >= count) start -= count; }
    particles_update();

    meter_end();
    t++;                                    /* text is slow: one item per frame, spread over 16 frames */
    if ((t & 15) == 0) meter_print(0, 1, 0);
    else if ((t & 15) == 4) text_print_num(6, 0, count, 2);
    else if ((t & 15) == 8) text_print_num(15, 0, shown, 2);
    else if ((t & 15) == 12) { text_print(0, 2, mode_names[ball_mode]); text_print(8, 2, flicker ? "FLICKER" : "       "); }
}
