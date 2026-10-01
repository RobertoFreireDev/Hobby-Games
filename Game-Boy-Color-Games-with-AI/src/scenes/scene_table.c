#include "engine/engine.h"
#include "scenes.h"
/* NOT banked. The engine calls scene functions through plain function pointers, which can't reach a
   switchable bank, so each pointer is a tiny bank-0 stub that makes the BANKED call (the call switches
   to the scene's bank and back). */

static void title_e(void)   { title_enter(); }    static void title_u(void)   { title_update(); }
static void menu_e(void)    { menu_enter(); }     static void menu_u(void)    { menu_update(); }
static void level_e(void)   { level_enter(); }    static void cave_e(void)    { cave_enter(); }
static void play_u(void)    { play_update(); }    static void play_l(void)    { play_leave(); }
static void win_e(void)     { win_enter(); }      static void win_u(void)     { win_update(); }
static void over_e(void)    { over_enter(); }     static void over_u(void)    { over_update(); }
static void sprites_e(void) { sprites_enter(); }  static void sprites_u(void) { sprites_update(); }
static void scroll_e(void)  { scroll_enter(); }   static void scroll_u(void)  { scroll_update(); }
static void cpu_e(void)     { cpu_enter(); }      static void cpu_u(void)     { cpu_update(); }
static void cpu_l(void)     { cpu_leave(); }
static void memory_e(void)  { memory_enter(); }   static void memory_u(void)  { memory_update(); }
static void sound_e(void)   { sound_enter(); }    static void sound_u(void)   { sound_update(); }
static void rpg_e(void)     { rpg_enter(); }      static void rpg_u(void)     { rpg_update(); }

const scene_t scene_title   = { title_e,   title_u,   0 };
const scene_t scene_menu    = { menu_e,    menu_u,    0 };
const scene_t scene_level   = { level_e,   play_u,    play_l };
const scene_t scene_cave    = { cave_e,    play_u,    play_l };
const scene_t scene_win     = { win_e,     win_u,     0 };
const scene_t scene_over    = { over_e,    over_u,    0 };
const scene_t scene_sprites = { sprites_e, sprites_u, 0 };
const scene_t scene_scroll  = { scroll_e,  scroll_u,  0 };
const scene_t scene_cpu     = { cpu_e,     cpu_u,     cpu_l };
const scene_t scene_memory  = { memory_e,  memory_u,  0 };
const scene_t scene_sound   = { sound_e,   sound_u,   0 };
const scene_t scene_rpg     = { rpg_e,     rpg_u,     0 };
