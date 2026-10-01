#include "engine/engine.h"

palette_color_t pal_ram[64];
static uint8_t fade_level, fade_white;
static palette_color_t tmp[64];      /* pal_ram at the current fade level, as uploaded */

static uint8_t lut[32];              /* channel value 0-31 -> faded value at the current level */

/* adds only: 192 software multiplies per call made one call longer than a frame */
static void lut_build(void) {
    uint8_t v, acc = 0;
    if (fade_white) { v = 31; do { lut[v] = v + (acc >> 3); acc += fade_level; } while (v--); }   /* acc = (31-v)*level */
    else            { for (v = 0; v < 32; v++) { lut[v] = v - (acc >> 3); acc += fade_level; } } /* acc = v*level */
}

/* tmp[i] = pal_ram[i] through lut, for n colors from i. Byte math: a color is lo = gggrrrrr, hi = 0bbbbbgg */
static uint8_t lo, hi, g;             /* statics: SDCC reaches them directly, stack temporaries cost more */
static void convert(uint8_t i, uint8_t n) {
    const uint8_t *s = (const uint8_t *)&pal_ram[i];
    uint8_t *d = (uint8_t *)&tmp[i];
    do {
        lo = *s++; hi = *s++;
        g = lut[(uint8_t)(lo >> 5) | (uint8_t)((hi & 3) << 3)];
        *d++ = lut[lo & 31] | (uint8_t)(g << 5);
        *d++ = (g >> 3) | (uint8_t)(lut[(hi >> 2) & 31] << 2);
    } while (--n);
}

/* n colors from palette entry i (0-31 BG, 32-63 OBJ) to palette RAM, auto-increment, from pal_ram (level 0) or
   tmp. Palette RAM is locked only while the LCD draws a line (mode 3): once STAT shows mode 0 or 1 at least the
   80 dots of mode 2 remain, room for both bytes of a color, so one check per color (~40 cycles per byte). */
static void upload(uint8_t i, uint8_t n) {
    const uint8_t *s = (const uint8_t *)(fade_level ? &tmp[i] : &pal_ram[i]);
    if (i < 32) {
        BCPS_REG = BCPSF_AUTOINC | (uint8_t)(i << 1);
        do { while (STAT_REG & STATF_BUSY); BCPD_REG = *s++; BCPD_REG = *s++; } while (--n);
    } else {
        OCPS_REG = OCPSF_AUTOINC | (uint8_t)((i - 32) << 1);
        do { while (STAT_REG & STATF_BUSY); OCPD_REG = *s++; OCPD_REG = *s++; } while (--n);
    }
}

void fade_apply(void) {
    if (fade_level) lut_build();                /* level 0 uploads pal_ram as it is */
    fade_apply_colors(0, 32);
    fade_apply_colors(32, 32);
}

/* only colors i..i+n-1 changed in pal_ram (gfx_set_*_palette): convert and write just those; at level 0 there
   is nothing to convert */
void fade_apply_colors(uint8_t i, uint8_t n) {
    if (fade_level) convert(i, n);
    upload(i, n);
}

void fade_init(void) {
    uint8_t i;
    for (i = 0; i < 64; i++) pal_ram[i] = 0;
    fade_level = 8; fade_white = 0;
    fade_apply();
}

void fade_set_level(uint8_t level) {
    fade_level = level;
    fade_apply();
}

/* one step: convert while the frame is drawn, then write the colors right after vsync, inside VBlank
   (converting first put the writes ~20,000 cycles past the start of VBlank, so a step could tear) */
static void fade_step(uint8_t level, uint8_t fps) {
    fade_level = level;
    lut_build();
    convert(0, 64);
    vsync();
    upload(0, 32);
    upload(32, 32);
    while (--fps) vsync();
}

void fade_out(uint8_t fps, uint8_t to_white) {
    uint8_t s;
    fade_white = to_white;
    if (!fps) fps = 1;
    for (s = 1; s <= 8; s++) fade_step(s, fps);
}

void fade_in(uint8_t fps, uint8_t from_white) {
    uint8_t s = 8;
    fade_white = from_white;
    if (!fps) fps = 1;
    do fade_step(--s, fps); while (s);
}
