#ifndef COINS_H
#define COINS_H
#include "engine/engine.h"

#define MAX_COINS 24                /* per area; bit n of the area's coins_taken mask = n-th coin */
extern sprite_t coin_spr;           /* loaded by the scene */

void coins_clear(uint32_t *taken) BANKED;          /* taken: persistent mask in game state (RAM) */
void coins_add(uint16_t tx, uint16_t ty) BANKED;   /* in map scan order */
uint8_t coins_update(const body_t *b) BANKED;      /* spin, draw, collect: returns coins picked this frame */
void coins_pop(int16_t wx, int16_t wy) BANKED;     /* floating coin that rises (tween) */
#endif
