#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/meter.h"

/* Scroll stress: 200x64 banked map, camera streaming on both axes. AUTO flies a Lissajous path; at the
   fastest speeds cam_follow moves 8 px per frame on both axes (a new 19-cell column and 21-cell row
   every frame). MANUAL: the d-pad drives the camera target. HUD on the window (2 bottom rows).
   A auto/manual, B speed, SELECT camera shake, START back. */

static uint16_t phase;              /* Lissajous phase, 1024 per table step */
static int16_t tx, ty;              /* camera target, world pixels (top-left) */
static uint8_t manual, speed, t;

/* sin * 127, 64 steps per turn */
static const int8_t sin64[64] = {
    0, 12, 25, 37, 49, 60, 71, 81, 90, 98, 106, 112, 117, 122, 125, 126,
    127, 126, 125, 122, 117, 112, 106, 98, 90, 81, 71, 60, 49, 37, 25, 12,
    0, -12, -25, -37, -49, -60, -71, -81, -90, -98, -106, -112, -117, -122, -125, -126,
    -127, -126, -125, -122, -117, -112, -106, -98, -90, -81, -71, -60, -49, -37, -25, -12
};
static const uint8_t auto_step[4] = { 24, 48, 96, 160 };    /* phase per frame */
static const uint8_t manual_px[4] = { 1, 2, 4, 8 };         /* px per frame */

static void hud_labels(void) {
    text_print_win(0, 1, manual ? "MAN  " : "AUTO ");
    text_print_win(5, 1, "SPD  X     Y   ");
    text_print_num_win(8, 1, speed + 1, 1);
}

void scroll_enter(void) BANKED {
    map_load(&map_scroll, BANK(map_scroll));
    tx = 720; ty = 184;
    cam_set(tx, ty);
    phase = 0; manual = 0; speed = 2; t = 0;
    text_print_win(0, 0, "                    ");
    meter_labels(0, 0, 1);
    hud_labels();
    move_win(7, 128);
    SHOW_WIN;
    meter_reset();
}

void scroll_update(void) BANKED {
    int8_t s;
    uint8_t v;

    meter_begin();
    if (KEY_PRESSED(J_A)) { manual ^= 1; hud_labels(); }
    if (KEY_PRESSED(J_B)) { speed = (speed + 1) & 3; hud_labels(); }
    if (KEY_PRESSED(J_SELECT)) cam_shake(30, 3);
    if (KEY_PRESSED(J_START)) scene_goto(&scene_menu, TRANS_FADE_BLACK);

    if (manual) {
        v = manual_px[speed];
        if (KEY_HELD(J_LEFT)) tx -= v;
        if (KEY_HELD(J_RIGHT)) tx += v;
        if (KEY_HELD(J_UP)) ty -= v;
        if (KEY_HELD(J_DOWN)) ty += v;
        tx = CLAMP(tx, 0, 1600 - 160);
        ty = CLAMP(ty, 0, 512 - 144);
    } else {
        phase += auto_step[speed];
        s = sin64[(phase >> 10) & 63];                     /* x: +-635 px around the middle */
        tx = 720 + (s << 2) + s;
        s = sin64[((phase >> 9) + (phase >> 10) + 16) & 63];   /* y: 1.5x frequency, +-167 px */
        ty = 184 + s + (s >> 1) - (s >> 3) - (s >> 4);
    }
    cam_follow(tx + 80, ty + 72);

    meter_end();
    t++;                                    /* text is slow: one item per frame */
    if ((t & 15) == 0) meter_print(0, 0, 1);
    else if ((t & 7) == 4) text_print_num_win(11, 1, (uint16_t)cam_x, 4);
    else if ((t & 7) == 6) text_print_num_win(17, 1, (uint16_t)cam_y, 3);
}
