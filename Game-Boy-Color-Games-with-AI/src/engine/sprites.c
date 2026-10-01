#include "engine/engine.h"

uint8_t spr_next;                 /* OAM entries used this frame (particles.c writes OAM directly too) */
static uint8_t spr_last;

void spr_begin(void) { spr_next = 0; }

void spr_end(void) {
    uint8_t *o = (uint8_t *)shadow_OAM + (uint8_t)(spr_next << 2);
    uint8_t n;
    if (spr_last > spr_next) {                   /* hide the entries used last frame but not this one */
        n = spr_last - spr_next;
        do { *o = 0; o += 4; } while (--n);
    }
    spr_last = spr_next;
}

uint8_t spr_put(uint8_t tile, int16_t sx, int16_t sy, uint8_t prop) {
    uint8_t *o;
    /* visible when -8 < sx < 160 and -8 < sy < 144: one unsigned compare per axis */
    if (spr_next >= 40 || (uint16_t)(sx + 7) >= 167 || (uint16_t)(sy + 7) >= 151) return 0;
    o = (uint8_t *)shadow_OAM + (uint8_t)(spr_next << 2);
    spr_next++;
    *o++ = (uint8_t)sy + 16;
    *o++ = (uint8_t)sx + 8;
    *o++ = tile;
    *o = prop;
    return 1;
}

/* One row of spr_draw, straight into shadow OAM: tile d_t at x, then d_t + d_step at x + 8, ... until x reaches
   d_xend. The loop invariants are globals so SDCC keeps o, x and the tile in registers (~240 cycles per tile).
   8-bit culling (visible OAM x is 1..167) is exact because spr_draw rejected positions far off screen,
   and the 40-entry limit is a compare on the pointer: shadow_OAM is 256-byte aligned (OAM DMA needs it). */
static uint8_t d_y, d_t, d_step, d_xend, d_prop, d_x, d_rstep;
static uint8_t *draw_row(uint8_t *o, uint8_t x) {
    uint8_t t = d_t;
    do {
        if ((uint8_t)(x - 1) < 167 && (uint8_t)o < 160) { *o++ = d_y; *o++ = x; *o++ = t; *o++ = d_prop; }
        x += 8; t += d_step;
    } while (x != d_xend);
    return o;
}

void spr_draw(const sprite_t *s, uint8_t frame, int16_t sx, int16_t sy, uint8_t flags) {
    const uint8_t *p = (const uint8_t *)s;   /* base, w, h, tpf, frames, pal: read in order */
    uint8_t t, w, h, tpf;
    uint8_t *o;
    /* Far off screen: sx < -96 or > 159, sy < -112 or > 143. Inside those ranges a tile's OAM x (y) is either
       visible or, off screen, lands in 168..255 (160..255), wrapping included, for sprites up to 11x12 tiles */
    if ((uint16_t)(sx + 96) >= 256 || (uint16_t)(sy + 112) >= 256) return;
    t = *p++; w = *p++; h = *p++; tpf = *p;
    d_prop = p[2] | flags;
    d_rstep = w;                               /* t = top-left tile: base + frame * tpf, then the flips */
    if (flags & SPR_FLIPY) { t += tpf - w; d_rstep = (uint8_t)(0 - w); }   /* tpf - w = (h - 1) * w */
    d_step = 1;
    if (flags & SPR_FLIPX) { t += w - 1; d_step = 0xFF; }
    while (frame) { if (frame & 1) t += tpf; tpf <<= 1; frame >>= 1; }   /* shift and add, no library call */
    d_t = t;
    d_x = (uint8_t)sx + 8;
    d_xend = d_x + (w << 3);
    d_y = (uint8_t)sy + 16;
    o = (uint8_t *)shadow_OAM + (uint8_t)(spr_next << 2);
    do {
        if ((uint8_t)(d_y - 9) < 151) o = draw_row(o, d_x);   /* visible OAM y is 9..159 */
        d_y += 8; d_t += d_rstep;
    } while (--h);
    spr_next = (uint8_t)(uint16_t)o >> 2;
}

void spr_hide_all(void) {
    spr_next = 0; spr_last = 40;
    spr_end();
}
