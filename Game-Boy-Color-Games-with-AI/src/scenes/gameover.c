#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/state.h"

/* Game over: text + jingle, then input_wait_press (blocking) -> menu. */
static uint8_t first;

void over_enter(void) BANKED {
    text_print(5, 7, "GAME  OVER");
    text_print(4, 9, "SCORE");
    text_print_num(11, 9, game_score, 5);
    text_print(3, 13, "PRESS A OR START");
    first = 1;
    music_play(&mus_over);
}

void over_update(void) BANKED {
    if (first) { first = 0; return; }          /* the fade-in runs after the first frame */
    input_wait_press(J_A | J_START);
    scene_goto(&scene_menu, TRANS_FADE_BLACK);
}
