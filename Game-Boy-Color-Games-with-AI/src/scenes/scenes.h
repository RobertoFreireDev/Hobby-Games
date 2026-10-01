#ifndef SCENES_H
#define SCENES_H
#include "engine/engine.h"
/* Every game defines at least scene_title (main.c starts it). Add the other scenes here. */
extern const scene_t scene_title, scene_menu, scene_level, scene_cave, scene_win, scene_over;
extern const scene_t scene_sprites, scene_scroll, scene_cpu, scene_memory, scene_sound, scene_rpg;

/* Scene code lives in switchable ROM banks (bank 0 is full with the engine, see GAME.md).
   scene_table.c (not banked) holds the scene_t structs and small stubs that make these BANKED calls. */
void title_enter(void) BANKED;    void title_update(void) BANKED;
void menu_enter(void) BANKED;     void menu_update(void) BANKED;
void level_enter(void) BANKED;    void cave_enter(void) BANKED;
void play_update(void) BANKED;    void play_leave(void) BANKED;
void win_enter(void) BANKED;      void win_update(void) BANKED;
void over_enter(void) BANKED;     void over_update(void) BANKED;
void sprites_enter(void) BANKED;  void sprites_update(void) BANKED;
void scroll_enter(void) BANKED;   void scroll_update(void) BANKED;
void cpu_enter(void) BANKED;      void cpu_update(void) BANKED;     void cpu_leave(void) BANKED;
void memory_enter(void) BANKED;   void memory_update(void) BANKED;
void sound_enter(void) BANKED;    void sound_update(void) BANKED;
void rpg_enter(void) BANKED;      void rpg_update(void) BANKED;
#endif
