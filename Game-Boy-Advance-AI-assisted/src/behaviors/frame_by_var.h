// frame_by_var - a variable picks which picture of its sprite sheet it shows. See the .c.
#ifndef BHV_FRAME_BY_VAR_H
#define BHV_FRAME_BY_VAR_H

#include "engine/actor.h"

// Called once when the actor appears.
void bhv_frame_by_var_init(Actor *self, const void *params);
// Called every tick.
void bhv_frame_by_var_update(Actor *self, const void *params);

#endif
