#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/state.h"
#include "game/save.h"

/* Main menu: menu_run (blocking) on the BG, 8 options (rows 4-11), plus cartridge and save info (rows 12-16). */
static uint8_t first;

static const char * const options[] = {
    "PLAY GAME", "PLAY GAME 2", "SPRITE STRESS", "SCROLL STRESS", "CPU STRESS", "MEMORY TEST", "SOUND TEST", "TITLE"
};

void menu_enter(void) BANKED {
    uint8_t rom_code = *(const uint8_t *)0x0148;          /* cartridge header: ROM size = 32 KB << code */
    text_print(4, 1, "ENGINE  LAB");
    text_print(4, 2, "-----------");
    text_print(1, 12, "ROM    K  BANKS");
    text_print_num(5, 12, (uint16_t)32 << rom_code, 4);
    text_print_num(17, 12, (uint16_t)2 << rom_code, 3);
    text_print(1, 13, "SRAM 8K  WRAM 32K");
    text_print(1, 15, "BOOTS       SAVE");
    text_print_num(7, 15, save.boots, 5);
    text_print_num(18, 15, save.saves, 2);
    text_print(1, 16, "BEST   C  WINS");
    text_print_num(6, 16, save.best_coins, 2);
    text_print_num(16, 16, save.wins, 2);
    first = 1;
    music_play(&mus_title);
}

void menu_update(void) BANKED {
    if (first) { first = 0; return; }                     /* let the fade-in finish before blocking */
    switch (menu_run(3, 4, options, 8)) {
    case 0: state_new_game(); scene_goto(&scene_level, TRANS_FADE_BLACK); break;
    case 1: scene_goto(&scene_rpg, TRANS_FADE_BLACK); break;
    case 2: scene_goto(&scene_sprites, TRANS_FADE_BLACK); break;
    case 3: scene_goto(&scene_scroll, TRANS_FADE_BLACK); break;
    case 4: scene_goto(&scene_cpu, TRANS_FADE_BLACK); break;
    case 5: scene_goto(&scene_memory, TRANS_FADE_BLACK); break;
    case 6: scene_goto(&scene_sound, TRANS_NONE); break;
    default: scene_goto(&scene_title, TRANS_FADE_WHITE); break;
    }
}
