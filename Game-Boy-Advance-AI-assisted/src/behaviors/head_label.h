// head_label - a word over the actor's head, picked by a variable. See the .c.
#ifndef BHV_HEAD_LABEL_H
#define BHV_HEAD_LABEL_H

#include "engine/actor.h"

// Called every tick.
void bhv_head_label_update(Actor *self, const void *params);

#endif
