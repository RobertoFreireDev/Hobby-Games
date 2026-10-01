#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/state.h"
#include "game/save.h"
#include "game/player.h"

/* Title: LAB logo map, hero slides in (tween EASE_OUT) then hops (tween_busy), brick palette cycles. */
static uint8_t t;
static int16_t hx, hy;

/* palette 1 (bricks + clouds): colors 0-1 stay (sky, cloud white), 2-3 cycle */
static const palette_color_t brick_cycle[4][4] = {
    { RGB8(152,208,248), RGB8(216,216,224), RGB8(136,136,152), RGB8(56,56,80) },
    { RGB8(152,208,248), RGB8(216,216,224), RGB8(208,88,72),   RGB8(96,24,32) },
    { RGB8(152,208,248), RGB8(216,216,224), RGB8(88,120,216),  RGB8(32,40,112) },
    { RGB8(152,208,248), RGB8(216,216,224), RGB8(224,168,40),  RGB8(112,64,16) },
};

void title_enter(void) BANKED {
    if (!booted) {                  /* count this power-on in SRAM once */
        booted = 1;
        save_load();
        save.boots++;
        save_write();
    }
    map_load(&map_title, BANK(map_title));
    cam_set(0, 0);
    gfx_load_sprite(&hero_spr, &spr_hero, BANK(spr_hero));
    text_print(5, 2, "GBC ENGINE");
    text_print(3, 17, "2026 TEST CART");
    hx = -16; hy = 104;
    tween_start(&hx, 72, 60, EASE_OUT);
    t = 0;
    music_play(&mus_title);
}

void title_update(void) BANKED {
    t++;
    if ((t & 31) == 0) text_print(5, 11, "PRESS START");
    if ((t & 31) == 16) text_clear(5, 11, 11, 1);
    if ((t & 15) == 0) gfx_set_bkg_palette(1, brick_cycle[(t >> 4) & 3]);

    if (!tween_busy(&hx) && !tween_busy(&hy))      /* landed: hop again */
        tween_start(&hy, hy == 104 ? 88 : 104, 14, hy == 104 ? EASE_OUT : EASE_IN);
    tween_update();
    spr_draw(&hero_spr, tween_busy(&hx) ? ((t >> 3) & 1) + 1 : (hy == 104 ? 0 : 3), hx, hy, 0);

    if (KEY_PRESSED(J_START)) {
        rand_seed();
        scene_goto(&scene_menu, TRANS_FADE_BLACK);
    }
}
