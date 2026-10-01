#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"

/* Sound test: non-blocking list (cursor stays where it was, unlike menu_run), live channel activity
   read from NR52. UP/DOWN select, A play, B stop music, START back. */
#define ITEMS 15
static uint8_t sel, t;

static const char * const names[ITEMS] = {
    "TITLE THEME", "LEVEL THEME", "CAVE THEME", "WIN JINGLE", "GAME OVER",
    "SFX JUMP", "SFX COIN", "SFX HURT", "SFX BUMP", "SFX SPRING", "SFX FLAG", "SFX STOMP", "SFX BOOM",
    "SFX MENU", "STOP MUSIC"
};

static void draw_cursor(void) {
    uint8_t i;
    for (i = 0; i < ITEMS; i++) text_print(1, 1 + i, i == sel ? ">" : " ");
}

void sound_enter(void) BANKED {
    uint8_t i;
    text_print(5, 0, "SOUND TEST");
    for (i = 0; i < ITEMS; i++) text_print(3, 1 + i, names[i]);
    text_print(0, 16, "CH 1 2 3 4");
    sel = 0; t = 0;
    draw_cursor();
}

void sound_update(void) BANKED {
    uint8_t nr52, i;
    if (KEY_PRESSED(J_UP))   { sel = sel ? sel - 1 : ITEMS - 1; draw_cursor(); }
    if (KEY_PRESSED(J_DOWN)) { sel = sel + 1 < ITEMS ? sel + 1 : 0; draw_cursor(); }
    if (KEY_PRESSED(J_B)) music_stop();
    if (KEY_PRESSED(J_A)) {
        switch (sel) {
        case 0: music_play(&mus_title); break;
        case 1: music_play(&mus_level); break;
        case 2: music_play(&mus_cave); break;
        case 3: music_play(&mus_win); break;
        case 4: music_play(&mus_over); break;
        case 5: sfx_play(&sfx_jump); break;
        case 6: sfx_play(&sfx_coin); break;
        case 7: sfx_play(&sfx_hurt); break;
        case 8: sfx_play(&sfx_bump); break;
        case 9: sfx_play(&sfx_spring); break;
        case 10: sfx_play(&sfx_flag); break;
        case 11: sfx_play(&sfx_stomp); break;
        case 12: sfx_play(&sfx_boom); break;
        case 13: sfx_play(&sfx_menu); break;
        default: music_stop(); break;
        }
    }
    if (KEY_PRESSED(J_START)) scene_goto(&scene_menu, TRANS_NONE);
    if (++t & 1) return;
    nr52 = NR52_REG;                               /* bits 0-3: channel 1-4 currently sounding */
    for (i = 0; i < 4; i++) text_print(3 + (i << 1), 17, (nr52 & (1 << i)) ? "*" : "-");
}
