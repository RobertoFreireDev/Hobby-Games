#pragma bank 255
#include "engine/engine.h"
#include "enemies.h"
#include "fx.h"

typedef struct { uint8_t active; body_t b; int8_t dir; anim_t anim; } slime_t;   /* hitbox 14x7 in 16x8 */

/* slimes more than 32 px outside the screen are frozen and not drawn: tile collision costs ~12K cycles
   per body_move (GAME.md -> Performance), too much to simulate the whole level every frame */
#define NEAR_SCREEN(b) (UNFIX((b).x) > cam_x - 48 && UNFIX((b).x) < cam_x + 192 && \
                        UNFIX((b).y) > cam_y - 40 && UNFIX((b).y) < cam_y + 176)
static slime_t slimes[MAX_SLIMES];
static uint8_t tick;
sprite_t slime_spr;

static const uint8_t slime_frames[] = { 0, 1 };
static const anim_def_t anim_slime = { slime_frames, 2, 16, 1 };

void slimes_clear(void) BANKED {
    uint8_t i;
    for (i = 0; i < MAX_SLIMES; i++) slimes[i].active = 0;
}

void slimes_add(uint16_t tx, uint16_t ty) BANKED {
    uint8_t i;
    slime_t *s;
    for (i = 0; i < MAX_SLIMES; i++) {
        s = &slimes[i];
        if (s->active) continue;
        s->active = 1;
        s->b.w = 14; s->b.h = 7;
        s->b.x = FIX(tx * 8 + 1);
        s->b.y = FIX(ty * 8 + 1);
        s->b.vx = s->b.vy = 0;
        s->dir = (i & 1) ? 1 : -1;
        s->anim.def = 0;
        anim_play(&s->anim, &anim_slime);
        s->anim.i = i & 1;                          /* not all in step */
        return;
    }
}

void slimes_update(void) BANKED {
    uint8_t i;
    int16_t front;
    slime_t *s;
    tick++;
    for (i = 0; i < MAX_SLIMES; i++) {
        s = &slimes[i];
        if (!s->active || !NEAR_SCREEN(s->b)) continue;
        anim_update(&s->anim);
        if ((tick ^ i) & 1) continue;               /* physics every other frame (half of them each frame) */
        s->b.vx = s->dir > 0 ? 16 : -16;            /* 1 px per 2 frames = 0.5 px/frame */
        s->b.vy += 10;
        if (s->b.vy > FIX(4)) s->b.vy = FIX(4);
        if (body_move(&s->b) & (HIT_LEFT | HIT_RIGHT)) s->dir = -s->dir;
        else if (body_on_ground(&s->b)) {           /* turn at ledges: nothing to stand on ahead */
            front = s->dir > 0 ? UNFIX(s->b.x) + s->b.w : UNFIX(s->b.x) - 1;
            if (!(map_coll_px(front, UNFIX(s->b.y) + s->b.h) & (COLL_SOLID | COLL_TOP))) s->dir = -s->dir;
        }
    }
}

void slimes_draw(void) BANKED {
    uint8_t i;
    slime_t *s;
    for (i = 0; i < MAX_SLIMES; i++) {
        s = &slimes[i];
        if (!s->active || !NEAR_SCREEN(s->b)) continue;
        spr_draw(&slime_spr, anim_frame(&s->anim), W2S_X(UNFIX(s->b.x) - 1), W2S_Y(UNFIX(s->b.y) - 1),
                 s->dir > 0 ? SPR_FLIPX : 0);
    }
}

uint8_t slimes_touch(const body_t *b, uint8_t *stomp, int8_t *dir) BANKED {
    uint8_t i;
    slime_t *s;
    for (i = 0; i < MAX_SLIMES; i++) {
        s = &slimes[i];
        if (!s->active || !body_overlap(b, &s->b)) continue;
        *stomp = b->vy > 0 && UNFIX(b->y) + b->h <= UNFIX(s->b.y) + 4;
        *dir = UNFIX(s->b.x) > UNFIX(b->x) ? 1 : -1;
        return i + 1;
    }
    return 0;
}

void slimes_kill(uint8_t i) BANKED {
    slime_t *s = &slimes[i];
    s->active = 0;
    particles_emit(UNFIX(s->b.x) + 4, UNFIX(s->b.y), 6, &fx_dust);
}
