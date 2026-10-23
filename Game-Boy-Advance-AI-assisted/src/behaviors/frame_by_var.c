// frame_by_var - a variable picks which picture it shows, every tick: value `first` shows its
// animation as drawn, each 1 more shows it `frames` frames further on in its sprite sheet (below
// `first` = the first picture, past the last of its `steps` pictures = the last one). It changes
// the moment the variable does. The menu's garden plots show their soil, plant or item this way.
#include "frame_by_var.h"
#include "behavior_params.h"
#include "engine/vars.h"

static void pick(Actor *a, const Params_frame_by_var *p) {
    s32 k = vars_get(p->var) - p->first;
    if (k < 0) k = 0;
    if (k >= p->steps) k = p->steps - 1;
    a->frame_shift = (u8)(k * p->frames);
}

void bhv_frame_by_var_init(Actor *a, const void *params) { pick(a, params); }

void bhv_frame_by_var_update(Actor *a, const void *params) { pick(a, params); }
