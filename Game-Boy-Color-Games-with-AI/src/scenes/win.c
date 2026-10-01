#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/state.h"
#include "game/save.h"
#include "game/fx.h"

/* Win: stats, best result saved to SRAM, fireworks (particles). A or START -> menu. */
static uint8_t t;

void win_enter(void) BANKED {
    uint8_t best = 0;
    gfx_load_sprite(&fx_spark, &spr_spark, BANK(spr_spark));
    save.wins++;
    if (game_coins > save.best_coins || (game_coins == save.best_coins && game_frames < save.best_frames)) {
        save.best_coins = game_coins;
        save.best_frames = game_frames;
        best = 1;
    }
    save_write();
    text_print(4, 3, "YOU GOT THE");
    text_print(6, 4, "TROPHY!");
    text_print(3, 7, "COINS");      text_print_num(13, 7, game_coins, 2);
    text_print(3, 8, "SCORE");      text_print_num(10, 8, game_score, 5);
    text_print(3, 9, "TIME         S"); text_print_num(12, 9, game_frames / 60, 3);
    text_print(3, 10, "LIVES");     text_print_num(14, 10, game_lives, 1);
    if (best) text_print(4, 12, "NEW BEST SAVED");
    text_print(3, 15, "PRESS A OR START");
    t = 0;
    music_play(&mus_win);
}

void win_update(void) BANKED {
    t++;
    if ((t & 15) == 0) {
        particles_emit(24 + (rand() & 111), 24 + (rand() & 63), 8, &fx_firework);
        sfx_play(&sfx_stomp);
    }
    particles_update();
    if (KEY_PRESSED(J_A | J_START)) scene_goto(&scene_menu, TRANS_FADE_BLACK);
}
