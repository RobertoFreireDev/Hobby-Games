#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/state.h"
#include "game/save.h"
#include "game/player.h"
#include "game/enemies.h"
#include "game/coins.h"
#include "game/fx.h"

/* Gameplay, shared by scene_level (area 0, 120x24 scrolling map) and scene_cave (area 1, 40x18).
   Tile flag meanings are in GAME.md -> Tile flags. */

#define MAX_SIGNS 4
#define MAX_BLOCKS 4

static uint8_t area;                            /* 0 = level, 1 = cave */
static uint16_t start_tx, start_ty;             /* respawn point without a checkpoint */
static uint8_t sign_tx[MAX_SIGNS], sign_ty[MAX_SIGNS], sign_n;
static uint16_t block_tx[MAX_BLOCKS], block_ty[MAX_BLOCKS];
static uint8_t block_n;
static uint16_t last_ctx, last_cty;             /* camera tile when used blocks were last redrawn */
static uint16_t flag_tx, flag_ty;               /* checkpoint cell (level) */
static uint16_t trophy_tx, trophy_ty;           /* trophy cell (cave), for its sparkle */
static uint8_t dead;                            /* frames until respawn after a hazard */
static uint8_t hud_dirty, hud_sec, hud_next;
static uint16_t hud_time, hud_shown[4];         /* seconds shown; HUD values on screen */
static body_t nobody = { FIX(-100), FIX(-100), 0, 0, 1, 1 };   /* RAM: coins.c may be in another bank */

static const palette_color_t pal_cave_ui[4] = {  /* text_set_colors test: purple UI in the cave */
    RGB8(40, 16, 56), RGB8(16, 8, 24), RGB8(184, 120, 232), RGB8(255, 232, 160)
};

static const char * const pause_opts[] = { "CONTINUE", "QUIT TO MENU" };
static const char * const yes_no[] = { "YES", "NO" };

static const char * const level_signs[] = {
    "WELCOME TO ENGINE LAB! A JUMPS, UP READS SIGNS AND OPENS DOORS, START PAUSES.\f"
    "HIT ? BLOCKS FROM BELOW. BUSHES AND TALL GRASS ARE DRAWN OVER YOU.",
    "ARROW GATES ARE ONE-WAY: YOU PASS ONLY IN THE ARROW'S DIRECTION.\nCLIMB THE PLANKS FOR THE HIGH COINS.",
    0,                                          /* the third sign is the save sign */
};
static const char * const cave_sign =
    "THE TROPHY WAITS ON THE HIGH LEDGE.\fIN HERE THE TEXT COLORS CHANGED: THAT IS TEXT_SET_COLORS.";

/* ---------- HUD (window, bottom row): "C:00 L:3 S:00000 000" ---------- */

static const uint8_t hud_x[4] = { 2, 7, 11, 17 }, hud_len[4] = { 2, 1, 5, 3 };

static uint16_t hud_value(uint8_t i) {          /* coins, lives, score, seconds */
    if (i == 0) return game_coins;
    if (i == 1) return game_lives;
    if (i == 2) return game_score;
    return hud_time;
}

/* One changed value per frame (docs/debugging.md 13.1): printing costs ~3,500 cycles per character, and a
   coin pickup used to reprint the whole row in the frame that also emits particles. */
static void hud_draw(void) {
    uint8_t n, i;
    uint16_t v;
    for (n = 0; n < 4; n++) {
        i = hud_next;
        hud_next = (i + 1) & 3;
        v = hud_value(i);
        if (v != hud_shown[i]) { hud_shown[i] = v; text_print_num_win(hud_x[i], 0, v, hud_len[i]); return; }
    }
    hud_dirty = 0;                              /* everything on screen is current */
}

static void hud_show(void) {                    /* also after dialogs, which take over the window */
    uint8_t i;
    text_print_win(0, 0, "C:   L:  S:         ");
    hud_time = game_frames / 60;
    for (i = 0; i < 4; i++) { hud_shown[i] = hud_value(i); text_print_num_win(hud_x[i], 0, hud_shown[i], hud_len[i]); }
    hud_dirty = 0;
    move_win(7, 136);
    SHOW_WIN;
}

/* ---------- map objects ---------- */

/* One pass over the map finds every object. map_find()/map_find_tag() rescan from the top on every call
   (a whole 120x24 scan is ~1.3M cycles, 9 frames), so they are kept for single lookups on load. */
static void scan_map(void) {
    uint16_t x, y, w = map_w_px >> 3, h = map_h_px >> 3;
    char c;
    slimes_clear();
    coins_clear(&coins_taken[area]);
    sign_n = 0; block_n = 0;
    for (y = 0; y < h; y++)
        for (x = 0; x < w; x++) {
            c = map_char(x, y);
            if (c == 'o') coins_add(x, y);
            else if (c == 's') slimes_add(x, y);
            else if (c == 'S' && sign_n < MAX_SIGNS) { sign_tx[sign_n] = (uint8_t)x; sign_ty[sign_n] = (uint8_t)y; sign_n++; }
            else if (c == '?' && block_n < MAX_BLOCKS) { block_tx[block_n] = x; block_ty[block_n] = y; block_n++; }
            else if (c == 'F') { flag_tx = x; flag_ty = y; }
        }
}

/* map_set_tile only changes VRAM: streaming redraws '?' from the map, so used blocks are re-applied
   whenever the camera enters a new tile */
static void refresh_blocks(uint8_t force) {
    uint8_t i;
    uint16_t ctx = (uint16_t)cam_x >> 3, cty = (uint16_t)cam_y >> 3;
    if (!force && ctx == last_ctx && cty == last_cty) return;
    last_ctx = ctx; last_cty = cty;
    for (i = 0; i < block_n; i++)
        if (blocks_used & (1 << i)) map_set_tile(block_tx[i], block_ty[i], 'u');
}

static void bump_check(void) {                  /* head hit something: bump block (free flag 31, char '?') */
    uint8_t i, k;
    int16_t head = UNFIX(hero.b.y) - 1, px;
    for (k = 0; k < 2; k++) {                   /* the two top corners of the hitbox (10 px < one tile + 8) */
        px = UNFIX(hero.b.x) + (k ? hero.b.w - 1 : 0);
        if (map_char_px(px, head) != '?') continue;
        for (i = 0; i < block_n; i++) {
            if (block_tx[i] != ((uint16_t)px >> 3) || block_ty[i] != ((uint16_t)head >> 3)) continue;
            if (blocks_used & (1 << i)) break;
            blocks_used |= 1 << i;
            map_set_tile(block_tx[i], block_ty[i], 'u');
            coins_pop(block_tx[i] << 3, (block_ty[i] << 3) - 8);
            particles_emit(block_tx[i] << 3, (block_ty[i] << 3) - 4, 4, &fx_burst);
            game_coins++; game_score += 10; hud_dirty = 1;
            sfx_play(&sfx_coin);
            return;
        }
    }
    sfx_play(&sfx_bump);
}

static void read_sign(void) {
    uint8_t i, x0 = (uint8_t)(UNFIX(hero.b.x) >> 3), x1 = (uint8_t)((UNFIX(hero.b.x) + hero.b.w - 1) >> 3);
    for (i = 0; i < sign_n; i++) {
        if (sign_tx[i] < x0 || sign_tx[i] > x1) continue;
        if (area) dialog_show(cave_sign);
        else if (level_signs[i]) dialog_show(level_signs[i]);
        else {                                  /* save sign: SRAM write + read-back check */
            dialog_show("THIS SIGN WRITES A SAVE TO BATTERY RAM (SRAM) WITH A CHECKSUM.");
            if (dialog_choice("SAVE NOW?", yes_no, 2) == 0) {
                save.saves++;
                save_write();
                save_load();
                dialog_show(save_found ? "SAVED, READ BACK AND VERIFIED!" : "SAVE FAILED: CHECKSUM MISMATCH.");
            }
        }
        hud_show();
        return;
    }
}

/* ---------- life and death ---------- */

static void lose_life(void) {
    if (game_lives) game_lives--;
    hud_dirty = 1;
    if (!game_lives) scene_goto(&scene_over, TRANS_FADE_BLACK);
}

static void die(void) {                         /* hazard or fall: burst, then respawn */
    particles_emit(UNFIX(hero.b.x) + 5, UNFIX(hero.b.y) + 7, 8, &fx_blast);
    sfx_play(&sfx_boom);
    sfx_play(&sfx_hurt);
    cam_shake(16, 3);
    dead = 45;
    lose_life();
}

static void respawn(void) {
    if (area == 0 && check_set) player_init(check_tx, check_ty);
    else player_init(start_tx, start_ty);
    hero.invuln = 60;
    cam_set(UNFIX(hero.b.x) - 80, UNFIX(hero.b.y) - 72);
    refresh_blocks(1);
}

/* ---------- scene ---------- */

static void play_enter(uint8_t a) {
    uint16_t tx = 2, ty = 2;
    area = a;
    if (a) map_load(&map_cave, BANK(map_cave));
    else map_load(&map_level, BANK(map_level));
    gfx_load_sprite(&hero_spr, &spr_hero, BANK(spr_hero));
    gfx_load_sprite(&slime_spr, &spr_slime, BANK(spr_slime));
    gfx_load_sprite(&coin_spr, &spr_coin, BANK(spr_coin));
    gfx_load_sprite(&fx_spark, &spr_spark, BANK(spr_spark));
    if (g_enter == ENTER_START || !map_find('e', 0, &tx, &ty))   /* each area has one arrival 'e' (ENTERn) */
        map_find('P', 0, &tx, &ty);                                /* SPAWN0 */
    start_tx = tx; start_ty = ty;
    player_init(tx, ty);
    scan_map();
    cam_set(UNFIX(hero.b.x) - 80, UNFIX(hero.b.y) - 72);
    refresh_blocks(1);
    if (a) {
        text_set_colors(pal_cave_ui);
        map_find('T', 0, &trophy_tx, &trophy_ty);   /* small map: one scan is cheap */
    }
    hud_show();
    hud_sec = 0;
    dead = 0;
    music_play(a ? &mus_cave : &mus_level);
}

void level_enter(void) BANKED { play_enter(0); }
void cave_enter(void) BANKED { play_enter(1); }

void play_leave(void) BANKED {
    text_set_colors(pal_ui_default);
    HIDE_WIN;
}

void play_update(void) BANKED {
    uint8_t hit, i, stomp;
    int8_t dir;
    uint8_t f;

    if (game_frames != 0xFFFF) game_frames++;
    if (++hud_sec >= 60) { hud_sec = 0; hud_time = game_frames / 60; hud_dirty = 1; }   /* one division a second */

    if (dead) {                                 /* hero hidden, world keeps moving */
        if (--dead == 0) {
            if (!game_lives) return;            /* game over transition already requested */
            respawn();
        }
    } else {
        if (KEY_PRESSED(J_START)) {
            if (dialog_choice("PAUSED", pause_opts, 2) == 1) { scene_goto(&scene_menu, TRANS_FADE_BLACK); return; }
            hud_show();
        }
        hit = player_update();
        if (hit & HIT_UP) bump_check();

        f = body_touch_tags(&hero.b);
        if ((f & TAG_HAZARD) || UNFIX(hero.b.y) > (int16_t)map_h_px) { die(); }
        else {
            if ((f & TAG_SIGN) && KEY_PRESSED(J_UP)) read_sign();
            if (f & TAG_TROPHY) { scene_goto(&scene_win, TRANS_FADE_WHITE); }
            if ((f & TAG_CHECK) && !check_set) {
                check_set = 1;
                check_tx = flag_tx; check_ty = flag_ty;
                particles_emit(check_tx << 3, check_ty << 3, 6, &fx_burst);
                sfx_play(&sfx_flag);
            }
            if ((f & TAG_DOOR) && KEY_PRESSED(J_UP)) {
                g_enter = area ? 1 : 0;         /* GAME.md: level LEAVE0 -> cave ENTER0, cave LEAVE0 -> level ENTER1 */
                scene_goto(area ? &scene_level : &scene_cave, TRANS_FADE_WHITE);
            }
        }
    }

    slimes_update();
    if (!dead && (i = slimes_touch(&hero.b, &stomp, &dir)) != 0) {
        if (stomp) {
            slimes_kill(i - 1);
            player_bounce();
            game_score += 100; hud_dirty = 1;
            sfx_play(&sfx_stomp);
            cam_shake(6, 1);
        } else if (!hero.invuln) {
            player_hurt(dir);
            sfx_play(&sfx_hurt);
            cam_shake(10, 2);
            lose_life();
        }
    }

    cam_follow(UNFIX(hero.b.x) + 5, UNFIX(hero.b.y) + 7);
    refresh_blocks(0);

    /* draw: player first (on top), then coins, slimes, particles */
    if (!dead) player_draw();
    i = coins_update(dead ? &nobody : &hero.b);
    if (i) { game_coins += i; game_score += 10 * i; hud_dirty = 1; sfx_play(&sfx_coin); }
    slimes_draw();
    if (area && (game_frames & 31) == 0) particles_emit((trophy_tx << 3) + 4, trophy_ty << 3, 2, &fx_firework);
    particles_update();
    tween_update();
    if (hud_dirty) hud_draw();
}
