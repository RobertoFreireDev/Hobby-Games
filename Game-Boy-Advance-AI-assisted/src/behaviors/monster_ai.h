// monster_ai - wander at home, turn hostile near the player, attack, go home (see the .c).
#ifndef BHV_MONSTER_AI_H
#define BHV_MONSTER_AI_H

#include "engine/actor.h"

// Its modes; the mode is the first of its state words (ST_MODE in the .c).
enum { MODE_SLEEP, MODE_WANDER, MODE_HOSTILE, MODE_RETURN };

// Called once when the actor appears.
void bhv_monster_ai_init(Actor *self, const void *params);
// Called every tick.
void bhv_monster_ai_update(Actor *self, const void *params);
// True while the monster sleeps (a boss waiting for its turn): moves can't hit it yet.
int monster_ai_asleep(const Actor *a);
// True while it is hostile (it spotted the player and goes for it); `index` = its monster_ai's
// place in the logic list (actor_logic_index), -1 for none. Inline: IWRAM has no room for more code.
static inline int monster_ai_hostile(Actor *a, int index) {
    return index >= 0 && actor_state_of(a, index)[0] == MODE_HOSTILE;
}

#endif
