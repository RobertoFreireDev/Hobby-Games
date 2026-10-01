#include "engine/engine.h"
#include <string.h>

#define MAX_PARTICLES 12

/* Everything particles_update needs is copied in by particles_emit: no style or sprite pointer chains per frame */
typedef struct {
    /* changed every frame: the first PART_LIVE bytes are copied back */
    uint8_t life;             /* frames left, 0 = free slot */
    int16_t x, y, vy;         /* fixed 12.4, world */
    uint8_t frames_left;      /* animation frames still to come */
    uint8_t frame_timer, tile;
    /* fixed */
    int16_t vx;
    int8_t gravity;
    uint8_t frame_step, pal;
} particle_t;
#define PART_LIVE 10

static particle_t parts[MAX_PARTICLES];
static uint8_t next_slot;
/* The particle being worked on. SDCC reaches a static with direct addresses, far cheaper than through a
   struct pointer, so emit fills it and update copies each live particle in and back out. */
static particle_t c;

/* -speed..speed, uniform: a masked random byte, drawn again when above 2 * speed (under 2 tries on average) */
static uint8_t vel_span, vel_mask;
static int8_t rand_vel(void) {
    uint8_t r;
    do r = rand() & vel_mask; while (r > vel_span);
    return (int8_t)(r - (vel_span >> 1));
}

void particles_emit(int16_t wx, int16_t wy, uint8_t count, const particle_style_t *st) {
    const sprite_t *s = st->spr;
    uint8_t frames = s->frames, step = frames > 1 ? st->life / frames : 0xFF;   /* one division per call */
    if (!step) step = 1;
    vel_span = st->speed << 1;
    vel_mask = vel_span | (vel_span >> 1);                       /* smallest 2^n - 1 >= vel_span */
    vel_mask |= vel_mask >> 2;
    vel_mask |= vel_mask >> 4;
    c.life = st->life; c.gravity = st->gravity;
    c.x = FIX(wx); c.y = FIX(wy);
    c.frames_left = frames - 1; c.frame_timer = 0; c.frame_step = step;
    c.tile = s->base; c.pal = s->pal;
    while (count--) {
        c.vx = rand_vel();
        c.vy = rand_vel() + st->up;
        memcpy(&parts[next_slot], &c, sizeof c);
        if (++next_slot >= MAX_PARTICLES) next_slot = 0;     /* round robin = recycles the oldest */
    }
}

static particle_t *cur;
static int16_t sx, sy;
static uint8_t *oam;
void particles_update(void) {
    uint8_t i = MAX_PARTICLES, *o;
    cur = parts;
    oam = (uint8_t *)shadow_OAM + (uint8_t)(spr_next << 2);    /* 1x1: written straight to OAM */
    do {
        if (!cur->life) continue;
        memcpy(&c, cur, sizeof c);
        if (!--c.life) { cur->life = 0; continue; }
        c.vy += c.gravity;
        c.x += c.vx; c.y += c.vy;
        if (c.frames_left && ++c.frame_timer >= c.frame_step) {
            c.frame_timer = 0;
            c.tile++; c.frames_left--;
        }
        memcpy(cur, &c, PART_LIVE);
        sx = UNFIX(c.x) - cam_x;
        sy = UNFIX(c.y) - cam_y;
        /* same culling as spr_put; shadow_OAM is 256-byte aligned, so the low byte of oam counts the 40 entries */
        if ((uint16_t)(sx + 7) < 167 && (uint16_t)(sy + 7) < 151 && (uint8_t)(uint16_t)oam < 160) {
            o = oam;
            *o++ = (uint8_t)sy + 16; *o++ = (uint8_t)sx + 8; *o++ = c.tile; *o++ = c.pal;
            oam = o;
        }
    } while (cur++, --i);
    spr_next = (uint8_t)(uint16_t)oam >> 2;
}

void particles_clear(void) {
    uint8_t i;
    for (i = 0; i < MAX_PARTICLES; i++) parts[i].life = 0;
    next_slot = 0;
}
