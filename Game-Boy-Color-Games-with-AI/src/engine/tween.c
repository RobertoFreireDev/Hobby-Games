#include "engine/engine.h"
#include <string.h>

#define MAX_TWEENS 8

typedef struct {
    uint16_t pos;                 /* progress through the curve, 0..65535 */
    uint8_t left;                 /* frames left; pos and left are the part tween_update writes back */
    int16_t *target;              /* 0 = free slot */
    int16_t from, d;              /* d = to - from */
    uint16_t step;                /* 65536 / frames, rounded up */
    const uint8_t *tbl;           /* ease_tbl row */
} tween_t;
#define TWEEN_LIVE 3

static tween_t tweens[MAX_TWEENS];
static uint8_t active;            /* bit i = slot i runs: tween_update skips free slots and returns at once if 0 */
static tween_t c;                 /* the tween being updated: a static is reached with direct addresses */

/* ease curves at progress 0, 16, ..., 256 -> 0..256. Bytes: the final 256 is stored as 0, and the rise to the
   next entry is a byte subtraction, which wraps to the right value (0 - 240 = 16) */
static const uint8_t ease_tbl[4][17] = {
  {0,16,32,48,64,80,96,112,128,144,160,176,192,208,224,240,0},
  {0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225,0},
  {0,31,60,87,112,135,156,175,192,207,220,231,240,247,252,255,0},
  {0,2,8,18,32,50,72,98,128,158,184,206,224,238,248,254,0},
};

uint8_t tween_start(int16_t *target, int16_t to, uint8_t frames, uint8_t ease) {
    uint8_t i, free_i = 0xFF;
    tween_t *t;
    for (i = 0; i < MAX_TWEENS; i++) {
        if (tweens[i].target == target) { free_i = i; break; }   /* replace a tween on the same value */
        if (!tweens[i].target && free_i == 0xFF) free_i = i;
    }
    if (free_i == 0xFF) return 0;
    t = &tweens[free_i];
    active |= (uint8_t)(1 << free_i);
    if (!frames) frames = 1;
    t->target = target;
    t->from = *target;
    t->d = to - *target;
    t->pos = 0;
    t->step = 0xFFFF / frames + 1;    /* the only division: once per tween */
    t->tbl = ease_tbl[ease & 3];
    t->left = frames;
    return 1;
}

/* d * e / 256, rounded down, with 8x8 multiplies instead of a 32-bit one: d = dh * 256 + dl, so
   d * e / 256 = dh * e + dl * e / 256. Moves under 256 px (dh 0 or -1) need one multiply. */
static int16_t scale(int16_t d, uint8_t e) {
    int8_t dh = (int8_t)(d >> 8);
    int16_t r = (uint8_t)((uint16_t)((uint8_t)d * e) >> 8);
    if (dh == -1) r -= e;
    else if (dh) r += (int16_t)(dh * e);
    return r;
}

/* (r * f) >> 4 for f 0..15: four shift-adds, cheaper than the library multiply */
static uint8_t mul4(uint8_t r, uint8_t f) {
    uint16_t m = 0;
    if (f & 1) m += r;
    if (f & 2) m += (uint16_t)r << 1;
    if (f & 4) m += (uint16_t)r << 2;
    if (f & 8) m += (uint16_t)r << 3;
    return (uint8_t)(m >> 4);
}

void tween_update(void) {
    uint8_t m = active, bit = 1, p;
    const uint8_t *e;
    tween_t *t = tweens;
    for (; m; m >>= 1, bit <<= 1, t++) {
        if (!(m & 1)) continue;
        memcpy(&c, t, sizeof c);
        if (!--c.left) {
            *c.target = c.from + c.d;
            t->target = 0;
            active &= ~bit;
            continue;
        }
        c.pos += c.step;
        p = c.pos >> 8;                                    /* 0..255 */
        e = c.tbl + (p >> 4);
        p = e[0] + mul4(e[1] - e[0], p & 15);               /* < 256 while the tween runs */
        *c.target = c.from + scale(c.d, p);
        memcpy(t, &c, TWEEN_LIVE);
    }
}

uint8_t tween_busy(const int16_t *target) {
    uint8_t i;
    for (i = 0; i < MAX_TWEENS; i++) if (tweens[i].target == target) return 1;
    return 0;
}

void tween_clear(void) {
    uint8_t i;
    for (i = 0; i < MAX_TWEENS; i++) tweens[i].target = 0;
    active = 0;
}
