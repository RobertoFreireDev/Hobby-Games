// move_switch - something only a move of the right type changes (a gate). See the .c.
#ifndef BHV_MOVE_SWITCH_H
#define BHV_MOVE_SWITCH_H

#include "engine/actor.h"

// Called once when the actor appears.
void bhv_move_switch_init(Actor *self, const void *params);
// The effect of one of the player's moves touched it: count the hit (or thud, for another type).
void move_switch_touch(Actor *self, const MoveData *m);
// True for an actor with this behavior (moves.c asks it of the actors a move or zone touches).
static inline int move_switch_is(const Actor *a) {
    return a->active && actor_logic_index(a, BHV_MOVE_SWITCH) >= 0;
}

#endif
