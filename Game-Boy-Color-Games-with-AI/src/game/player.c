#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "player.h"

player_t hero;
sprite_t hero_spr;

static const uint8_t idle_frames[] = { 0 };
static const uint8_t walk_frames[] = { 1, 0, 2, 0 };
static const uint8_t jump_frames[] = { 3 };
static const anim_def_t anim_idle = { idle_frames, 1, 60, 1 };
static const anim_def_t anim_walk = { walk_frames, 4, 6, 1 };
static const anim_def_t anim_jump = { jump_frames, 1, 60, 1 };

#define GRAVITY   5
#define MAX_FALL  FIX(4)
#define WALK_MAX  24            /* 1.5 px/frame */
#define ACCEL     3
#define JUMP_VY   (-72)         /* 4.5 px/frame: about 4 tiles high */
#define SPRING_VY (-112)        /* 7 px/frame (engine limit is < 8): about 9 tiles */

char map_char_px(int16_t px, int16_t py) BANKED {
    if (px < 0 || py < 0 || (uint16_t)px >= map_w_px || (uint16_t)py >= map_h_px) return 0;
    return map_char((uint16_t)px >> 3, (uint16_t)py >> 3);
}

void player_init(uint16_t tx, uint16_t ty) BANKED {
    hero.b.w = 10; hero.b.h = 14;
    hero.b.x = FIX(tx * 8 + 3);
    hero.b.y = FIX(ty * 8 + 8 - 14);
    hero.b.vx = hero.b.vy = 0;
    hero.left = 0;
    hero.invuln = 0;
    hero.anim.def = 0;
    anim_play(&hero.anim, &anim_idle);
}

uint8_t player_update(void) BANKED {
    uint8_t hit;
    int16_t target = 0;
    if (KEY_HELD(J_LEFT))       { target = -WALK_MAX; hero.left = 1; }
    else if (KEY_HELD(J_RIGHT)) { target = WALK_MAX;  hero.left = 0; }
    hero.b.vx = approach(hero.b.vx, target, ACCEL);

    if (KEY_PRESSED(J_A) && body_on_ground(&hero.b)) { hero.b.vy = JUMP_VY; sfx_play(&sfx_jump); }
    if (KEY_RELEASED(J_A) && hero.b.vy < 0) hero.b.vy = -((-hero.b.vy) >> 1);   /* variable jump height */
    hero.b.vy += GRAVITY;
    if (hero.b.vy > MAX_FALL) hero.b.vy = MAX_FALL;

    hit = body_move(&hero.b);

    /* spring (free flag 32, map char 'z'): landing on it launches the player */
    if ((hit & HIT_DOWN) && map_char_px(UNFIX(hero.b.x) + 5, UNFIX(hero.b.y) + hero.b.h) == 'z') {
        hero.b.vy = SPRING_VY;
        sfx_play(&sfx_spring);
    }

    if (!body_on_ground(&hero.b)) anim_play(&hero.anim, &anim_jump);
    else if (hero.b.vx) anim_play(&hero.anim, &anim_walk);
    else anim_play(&hero.anim, &anim_idle);
    anim_update(&hero.anim);
    if (hero.invuln) hero.invuln--;
    return hit;
}

void player_draw(void) BANKED {
    if (hero.invuln & 4) return;
    spr_draw(&hero_spr, anim_frame(&hero.anim), W2S_X(UNFIX(hero.b.x) - 3), W2S_Y(UNFIX(hero.b.y) - 2),
             hero.left ? SPR_FLIPX : 0);
}

void player_hurt(int8_t dir) BANKED {
    hero.b.vx = dir > 0 ? -FIX(2) : FIX(2);
    hero.b.vy = -FIX(2);
    hero.invuln = 90;
}

void player_bounce(void) BANKED {
    hero.b.vy = KEY_HELD(J_A) ? JUMP_VY : -FIX(3);
}
