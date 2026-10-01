#ifndef FADE_H
#define FADE_H
#include "core.h"
extern palette_color_t pal_ram[64];   /* 0-31 BG, 32-63 OBJ */
void fade_init(void);                                  /* all black, level 8 */
void fade_out(uint8_t frames_per_step, uint8_t to_white);   /* BLOCKING, 8 steps */
void fade_in(uint8_t frames_per_step, uint8_t from_white);  /* BLOCKING */
void fade_set_level(uint8_t level);
void fade_apply(void);                                 /* all 64 colors of pal_ram at the current level */
void fade_apply_colors(uint8_t i, uint8_t n);         /* only pal_ram[i..i+n-1] (gfx_set_*_palette) */
#endif
