#ifndef ENEMIES_H
#define ENEMIES_H
#include "engine/engine.h"

#define MAX_SLIMES 6
extern sprite_t slime_spr;          /* loaded by the scene */

void slimes_clear(void) BANKED;
void slimes_add(uint16_t tx, uint16_t ty) BANKED;    /* on the bottom of cell (tx, ty) */
void slimes_update(void) BANKED;                     /* walk, turn at walls and ledges */
void slimes_draw(void) BANKED;
/* first slime overlapping b: returns index + 1 (0 = none); *stomp = 1 if b lands on top of it */
uint8_t slimes_touch(const body_t *b, uint8_t *stomp, int8_t *dir) BANKED;
void slimes_kill(uint8_t i) BANKED;                  /* index from slimes_touch() - 1 */
#endif
