// appear_if - shows up only while a variable check passes, else removes itself unseen. See the .c.
#ifndef BHV_APPEAR_IF_H
#define BHV_APPEAR_IF_H

#include "engine/actor.h"

// Called once when the actor appears: removes it when the check fails.
void bhv_appear_if_init(Actor *self, const void *params);
// Called every tick: removes it the moment the check fails.
void bhv_appear_if_update(Actor *self, const void *params);

#endif
