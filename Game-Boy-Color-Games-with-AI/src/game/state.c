#pragma bank 255
#include "engine/engine.h"
#include "state.h"

uint16_t game_score, game_frames;
uint8_t game_lives, game_coins;
uint8_t g_enter;
uint32_t coins_taken[2];
uint8_t blocks_used;
uint8_t check_set;
uint16_t check_tx, check_ty;
uint8_t booted;

void state_new_game(void) BANKED {
    game_score = 0;
    game_frames = 0;
    game_lives = 3;
    game_coins = 0;
    g_enter = ENTER_START;
    coins_taken[0] = coins_taken[1] = 0;
    blocks_used = 0;
    check_set = 0;
}
