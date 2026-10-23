// topdown_controller - walk in any direction with the D-pad (no gravity).
#ifndef BHV_TOPDOWN_CONTROLLER_H
#define BHV_TOPDOWN_CONTROLLER_H

#include "engine/actor.h"

// Called once when the actor appears.
void bhv_topdown_controller_init(Actor *self, const void *params);
// Called every tick.
void bhv_topdown_controller_update(Actor *self, const void *params);

#endif
