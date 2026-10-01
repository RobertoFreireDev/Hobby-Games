#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/overworld.h"
#include "game/meter.h"

/* PLAY GAME 2: top-down RPG on a 128x96-screen open world (1.5 MB of map data in 96 ROM banks), streamed
   through a 3x3 ring of screens around the player (src/game/overworld.c). The camera keeps the player centered.
   D-pad walk, B run, A read the sign / knock on the door in front, SELECT view: WALK, STATS (bank, screen
   loads, stalls, CPU), FLY (stats, no collision, the hero hovers; 4 px per frame, 8 with B). START: menu.
   HUD (window, bottom): area name + screen x,y; STATS/FLY add "BK bank LD loads ST stalls" and the CPU meter. */

#define HB_W 10                     /* hitbox at the feet, px; the 16x16 sprite is drawn 3 px left, 8 px above */
#define HB_H 8
#define DIR_DOWN  0
#define DIR_UP    1
#define DIR_RIGHT 2
#define DIR_LEFT  3
#define VIEW_WALK  0
#define VIEW_STATS 1
#define VIEW_FLY   2

static sprite_t hero;
static uint16_t hx, hy;             /* hitbox top-left, world px */
static uint8_t dir, walk_t, view, hud_item, t;
static uint8_t shown_sx, shown_sy, shown_bank;
static uint16_t shown_loads, shown_stalls;

static const char * const door_texts[] = {
    "NOBODY ANSWERS.", "THE DOOR IS LOCKED.", "\"GO AWAY! WE'RE SLEEPING!\"", "YOU HEAR SNORING INSIDE."
};

static uint8_t blocked(uint16_t x, uint16_t y) {
    return ow_coll(x, y, x + HB_W - 1, y + HB_H - 1) & COLL_SOLID;
}

/* 1 px along one axis. Blocked by a corner: slide 1 px sideways when 5 px that way would get past it. */
static void step(int8_t dx, int8_t dy) {
    uint16_t nx = hx + dx, ny = hy + dy;
    if (!blocked(nx, ny)) { hx = nx; hy = ny; return; }
    if (dx) {
        if (!blocked(nx, hy - 5) && !blocked(hx, hy - 1)) hy--;
        else if (!blocked(nx, hy + 5) && !blocked(hx, hy + 1)) hy++;
    } else {
        if (!blocked(hx - 5, ny) && !blocked(hx - 1, hy)) hx--;
        else if (!blocked(hx + 5, ny) && !blocked(hx + 1, hy)) hx++;
    }
}

static void hud_show(void) {
    uint8_t rows = view == VIEW_WALK ? 1 : 3, i;
    for (i = 0; i < rows; i++) text_print_win(0, i, "                    ");   /* the whole HUD is redrawn */
    move_win(7, 144 - (rows << 3));
    if (rows > 1) {
        text_print_win(0, 1, "BK    LD      ST");
        meter_labels(0, 2, 1);
    }
    SHOW_WIN;
    shown_sx = shown_sy = 0xFF;                         /* reprint every value */
    shown_bank = 0; shown_loads = shown_stalls = 0xFFFF;
}

/* text costs ~2-3K cycles per char: print one changed item per frame */
static void hud_update(void) {
    switch (hud_item++ & 3) {
    case 0:
        if (shown_sx != ow_sx || shown_sy != ow_sy) {
            text_print_win(0, 0, "            ");
            text_print_win(0, 0, ow_name());
            text_print_num_win(13, 0, ow_sx, 3);
            text_print_win(16, 0, ",");
            text_print_num_win(17, 0, ow_sy, 2);
            shown_sx = ow_sx; shown_sy = ow_sy;
            return;
        }
        break;
    case 1:
        if (view != VIEW_WALK && shown_bank != ow_bank()) {
            shown_bank = ow_bank();
            text_print_num_win(2, 1, shown_bank, 3);
            return;
        }
        break;
    case 2:
        if (view != VIEW_WALK && shown_loads != ow_loads) {
            shown_loads = ow_loads;
            text_print_num_win(8, 1, shown_loads, 5);
            return;
        }
        break;
    default:
        if (view != VIEW_WALK && shown_stalls != ow_stalls) {
            shown_stalls = ow_stalls;
            text_print_num_win(16, 1, shown_stalls, 3);
            return;
        }
        break;
    }
    if (view != VIEW_WALK && (t & 15) == 0) meter_print(0, 2, 1);
}

/* A: the cell 4 px in front of the hitbox's facing edge */
static void interact(void) {
    uint16_t x = hx + HB_W / 2, y = hy + HB_H / 2;
    uint8_t tag;
    const char *s;
    if (dir == DIR_DOWN) y += HB_H / 2 + 4;
    else if (dir == DIR_UP) y -= HB_H / 2 + 4;
    else if (dir == DIR_RIGHT) x += HB_W / 2 + 4;
    else x -= HB_W / 2 + 4;
    tag = ow_tag(x, y);
    if (tag & TAG_SIGN) {
        s = ow_sign(x, y);
        if (!s || !*s) return;
        dialog_show(s);
    } else if (tag & TAG_DOOR) {
        dialog_show(door_texts[(uint8_t)(x >> 4) & 3]);
    } else return;
    hud_show();                                         /* the dialog used the window */
}

void rpg_enter(void) BANKED {
    gfx_load_sprite(&hero, &spr_rpg_hero, BANK(spr_rpg_hero));
    hx = (uint16_t)WORLD_START_SX * 160 + WORLD_START_MX * 16 + (16 - HB_W) / 2;
    hy = (uint16_t)WORLD_START_SY * 144 + WORLD_START_MY * 16 + (16 - HB_H);
    dir = DIR_DOWN; walk_t = 0; view = VIEW_WALK; hud_item = 0; t = 0;
    ow_init(hx + HB_W / 2, hy + HB_H / 2);
    hud_show();
    meter_reset();
    music_play(&mus_level);
}

void rpg_update(void) BANKED {
    int8_t dx = 0, dy = 0;
    uint8_t speed, i, frame, flags = 0;

    meter_begin();
    ow_flush();                                         /* still in VBlank */
    t++;
    if (KEY_PRESSED(J_START)) { scene_goto(&scene_menu, TRANS_FADE_BLACK); return; }
    if (KEY_PRESSED(J_SELECT)) { view = view == VIEW_FLY ? VIEW_WALK : view + 1; hud_show(); meter_reset(); }
    if (KEY_PRESSED(J_A)) interact();

    if (KEY_HELD(J_LEFT)) { dx = -1; dir = DIR_LEFT; }
    else if (KEY_HELD(J_RIGHT)) { dx = 1; dir = DIR_RIGHT; }
    if (KEY_HELD(J_UP)) { dy = -1; if (!dx) dir = DIR_UP; }
    else if (KEY_HELD(J_DOWN)) { dy = 1; if (!dx) dir = DIR_DOWN; }

    if (view == VIEW_FLY) {                             /* no collision; stays inside the world */
        speed = KEY_HELD(J_B) ? 8 : 4;
        if (dx < 0) hx = hx > 16 + speed ? hx - speed : 16;
        if (dx > 0) hx = hx < WORLD_W * 160 - 32 - speed ? hx + speed : WORLD_W * 160 - 32;
        if (dy < 0) hy = hy > 16 + speed ? hy - speed : 16;
        if (dy > 0) hy = hy < WORLD_H * 144 - 32 - speed ? hy + speed : WORLD_H * 144 - 32;
    } else {
        speed = KEY_HELD(J_B) ? 2 : 1;
        if (blocked(hx, hy)) {                          /* landed on something in FLY: walk out freely */
            hx += dx * speed; hy += dy * speed;
        } else for (i = 0; i < speed; i++) {
            if (dx) step(dx, 0);
            if (dy) step(0, dy);
        }
    }
    if (dx | dy) walk_t += speed; else walk_t = 0;

    ow_update(hx + HB_W / 2, hy + HB_H / 2);

    /* walk cycle: down/up alternate stand and step (flipped every other step), sides alternate 2 frames */
    i = (walk_t >> 3) & 3;
    if (dir == DIR_DOWN || dir == DIR_UP) {
        frame = dir == DIR_UP ? 2 : 0;
        if (i & 1) frame++;
        if (i == 3) flags = SPR_FLIPX;
    } else {
        frame = 4 + (i & 1);
        if (dir == DIR_LEFT) flags = SPR_FLIPX;
    }
    i = view == VIEW_FLY ? 4 + ((t >> 4) & 1) : 0;         /* FLY: the hero hovers and bobs */
    spr_draw(&hero, frame, (int16_t)hx - 3 - ow_cam_x, (int16_t)hy - 8 - i - ow_cam_y, flags);

    meter_end();
    hud_update();
}
