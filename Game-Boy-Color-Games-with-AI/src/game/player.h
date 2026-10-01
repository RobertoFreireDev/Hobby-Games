#ifndef PLAYER_H
#define PLAYER_H
#include "engine/engine.h"

typedef struct { body_t b; anim_t anim; uint8_t left, invuln; } player_t;   /* hitbox 10x14 in a 16x16 sprite */

extern player_t hero;
extern sprite_t hero_spr;           /* loaded by the scene: gfx_load_sprite(&hero_spr, &spr_hero, BANK(spr_hero)) */

void player_init(uint16_t tx, uint16_t ty) BANKED;   /* stands on the bottom of cell (tx, ty) */
uint8_t player_update(void) BANKED;                  /* input, physics, spring, anim; returns HIT_* bits */
void player_draw(void) BANKED;                       /* blinks while invulnerable */
void player_hurt(int8_t dir) BANKED;                 /* knockback away from dir, 90 frames invulnerable */
void player_bounce(void) BANKED;                     /* after a stomp */
char map_char_px(int16_t px, int16_t py) BANKED;     /* map_char with bounds check (0 outside) */
#endif
