#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/fx.h"
#include "game/meter.h"

/* CPU stress: up to 32 bodies with gravity doing tile collision (body_move + body_touch_tags on the
   arena map: solid, one-way and hazard tiles), optional extras (FX: a particle fountain and/or 4 orbiters
   driven by all 8 tweens), and a SPARE counter: after the frame's work, a loop of 16-bit multiplies and divisions runs until
   scanline 136 and counts its iterations (how much CPU is left). SELECT switches the CPU between
   double speed (8 MHz, the engine default) and single speed (4 MHz).
   Starts light (4 bodies, no FX, 60 fps): add load and watch CPU/FPS.
   UP/DOWN +-1 body, LEFT/RIGHT +-4, A cycles FX, B spare loop, SELECT speed, START back. */

#define MAX_BODIES 32
static body_t bod[MAX_BODIES];
static uint8_t nb, fx, spare_on, slow, t;           /* fx bit 0 = fountain, bit 1 = tween orbiters */
static int16_t orb_x[4], orb_y[4];                  /* tween targets */
static uint16_t spare, spare_a, spare_b;
static sprite_t ball;

static void body_spawn(body_t *b) {
    uint8_t tries = 8;
    uint16_t cx, cy;
    do {                                            /* a random open cell inside the arena */
        cx = 1 + (rand() & 15);
        cy = 3 + (rand() & 7);
    } while (--tries && (map_coll(cx, cy) | map_tag(cx, cy)));
    b->x = FIX(cx << 3); b->y = FIX(cy << 3);
    b->w = 7; b->h = 7;
    b->vx = (rand() & 1) ? 20 + (rand() & 15) : -20 - (rand() & 15);
    b->vy = 0;
}

static void spare_loop(void) {                      /* burn the rest of the frame, count iterations */
    uint8_t ly;
    spare = 0;
    for (;;) {
        ly = LY_REG;
        if (ly >= 136 && ly < 144) break;
        spare_a = spare_a * 31 + spare_b;
        spare_b = (spare_a / 13) ^ spare_b;
        spare++;
    }
}

static const char * const fx_names[] = { "FX NONE ", "FX FOUNT", "FX TWEEN", "FX BOTH " };

static void labels(void) {
    text_print(0, 0, "BODIES    SPARE     ");
    meter_labels(0, 1, 0);
    text_print(0, 17, fx_names[fx]);
    text_print(12, 17, slow ? "1X 4MHZ" : "2X 8MHZ");
}

void cpu_enter(void) BANKED {
    uint8_t i;
    map_load(&map_arena, BANK(map_arena));
    cam_set(0, 0);
    gfx_load_sprite(&ball, &spr_ball, BANK(spr_ball));
    gfx_load_sprite(&fx_spark, &spr_spark, BANK(spr_spark));
    for (i = 0; i < MAX_BODIES; i++) body_spawn(&bod[i]);
    for (i = 0; i < 4; i++) { orb_x[i] = 80; orb_y[i] = 72; }
    nb = 4; fx = 0; spare_on = 1; slow = 0; t = 0;
    spare_a = 1; spare_b = 7; spare = 0;
    labels();
    meter_reset();
}

void cpu_leave(void) BANKED {
    if (slow) cpu_fast();                           /* the engine expects double speed */
}

void cpu_update(void) BANKED {
    uint8_t i, hit;
    int16_t vx;
    body_t *b;

    meter_begin();
    if (KEY_PRESSED(J_UP) && nb < MAX_BODIES) nb++;
    if (KEY_PRESSED(J_DOWN) && nb > 1) nb--;
    if (KEY_PRESSED(J_RIGHT)) nb = nb + 4 > MAX_BODIES ? MAX_BODIES : nb + 4;
    if (KEY_PRESSED(J_LEFT)) nb = nb > 4 ? nb - 4 : 1;
    if (KEY_PRESSED(J_A)) { fx = (fx + 1) & 3; labels(); }
    if (KEY_PRESSED(J_B)) { spare_on ^= 1; spare = 0; }
    if (KEY_PRESSED(J_SELECT)) {
        slow ^= 1;
        if (slow) cpu_slow(); else cpu_fast();
        labels();
        meter_reset();
    }
    if (KEY_PRESSED(J_START)) scene_goto(&scene_menu, TRANS_FADE_BLACK);

    /* bodies: gravity, collision, bounce; hazard tiles respawn them */
    for (i = 0; i < nb; i++) {
        b = &bod[i];
        vx = b->vx;
        b->vy += 4;
        if (b->vy > FIX(5)) b->vy = FIX(5);
        hit = body_move(b);
        if (hit & (HIT_LEFT | HIT_RIGHT)) b->vx = -vx;
        if (hit & HIT_DOWN) b->vy = -40 - (int16_t)(rand() & 31);
        if (body_touch_tags(b) & TAG_HAZARD) {
            particles_emit(UNFIX(b->x), UNFIX(b->y), 3, &fx_dust);
            body_spawn(b);
        }
    }

    /* orbiters: each axis is a tween; a new random target when it arrives (8 tweens busy) */
    for (i = 0; i < 4 && (fx & 2); i++) {
        if (!tween_busy(&orb_x[i])) tween_start(&orb_x[i], 12 + (rand() & 127), 20 + (rand() & 31), i);
        if (!tween_busy(&orb_y[i])) tween_start(&orb_y[i], 28 + (rand() & 63) + (rand() & 15), 20 + (rand() & 31), 3 - i);
    }
    tween_update();

    /* draw: orbiters first (on top), then bodies, then particles; OAM keeps the first 40 */
    if (fx & 2) for (i = 0; i < 4; i++) spr_draw(&fx_spark, 0, orb_x[i], orb_y[i], 0);
    for (i = 0; i < nb; i++) spr_put(ball.base, UNFIX(bod[i].x), UNFIX(bod[i].y), ball.pal);
    if ((fx & 1) && (t & 3) == 0) particles_emit(80, 120, 2, &fx_fountain);
    particles_update();

    meter_end();
    t++;                                            /* text is slow: one item per frame */
    if ((t & 15) == 0) meter_print(0, 1, 0);
    else if ((t & 15) == 4) text_print_num(7, 0, nb, 2);
    else if ((t & 15) == 8) text_print_num(16, 0, spare, 4);
    if (spare_on) spare_loop();
}
