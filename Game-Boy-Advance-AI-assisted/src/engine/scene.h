// scene.h - load / unload scenes, spawn their instances, screen fades.
#ifndef ENGINE_SCENE_H
#define ENGINE_SCENE_H

#include "data.h"

// Ask to switch to a scene. The switch happens at the start of the next scene_update.
void scene_goto(s16 node);
// Per frame: do a pending switch, run action lists, run actor logic (unless paused).
void scene_update(void);
// VBlank: write the fade level to the hardware.
void scene_vblank(void);
// The scene being played (NULL before the first one loads).
const SceneData *scene_current(void);
// Node id of the scene being played.
s16 scene_current_node(void);
// How many scenes have loaded so far (changes on every load, even of the same scene again, and
// whenever a screens-camera scene shows another screen).
u16 scene_loads(void);
// Screens camera: the screen showing (row x screen_cols + column), -1 when the scene has none.
s16 scene_screen(void);
// Screens camera: the top-left world pixel of the screen showing. Returns 0 when the scene has none.
int scene_screen_box(s32 *x, s32 *y);
// Screens camera: show the screen at (col, row) of the map. Leaving one, all of its things go but
// the players (the maps and the HUD stay), with the particles and floating words, and sprite VRAM and
// palettes are handed out again; then on_screen runs and the new screen's instances are placed (so
// what on_screen sets decides which of them appear).
void scene_enter_screen(s16 col, s16 row);
// Fade to black (to_black = 1) or back from black (0) over `ticks`.
void scene_fade(int to_black, int ticks);
// Light the screen up white, fading back to normal over `ticks` (a camera flash).
void scene_flash(int ticks);
// Spawn an object or particle burst at a world position. Returns the actor or NULL.
struct Actor *scene_spawn(s16 node, s32 x, s32 y);

#endif
