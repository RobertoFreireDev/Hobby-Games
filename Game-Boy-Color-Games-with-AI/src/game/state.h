#ifndef STATE_H
#define STATE_H
#include "engine/engine.h"

#define ENTER_START 0xFF            /* g_enter value for a new game: start at SPAWN0 ('P') */

extern uint16_t game_score, game_frames;   /* game_frames: play time in frames (stops at 65535) */
extern uint8_t game_lives, game_coins;
extern uint8_t g_enter;                    /* ENTERn the next play scene uses (docs/engine-api.md 7.6) */
extern uint32_t coins_taken[2];            /* per area (0 level, 1 cave): bit n = n-th coin collected */
extern uint8_t blocks_used;                /* bit n = n-th bump block of the level used */
extern uint8_t check_set;                  /* checkpoint reached in the level */
extern uint16_t check_tx, check_ty;
extern uint8_t booted;                     /* boot counted in SRAM this power-on */

void state_new_game(void) BANKED;
#endif
