// trigger_zone - run actions when the player enters or leaves the zone (as the zone, or with
// `as_player` as the player).
#include "trigger_zone.h"
#include "behavior_params.h"
#include "engine/actions.h"

enum { ST_TOUCHED, ST_INSIDE, ST_FIRED };

void bhv_trigger_zone_update(Actor *a, const void *params) {
    const Params_trigger_zone *p = params;
    u32 *st = bhv_state(a);
    u32 inside = st[ST_TOUCHED];        // set by the previous frame's physics
    st[ST_TOUCHED] = 0;
    Actor *self = p->as_player ? actor_player() : a;
    if (inside && !st[ST_INSIDE]) {
        if (!(p->once && st[ST_FIRED])) scripts_start(p->on_enter, self);
    } else if (!inside && st[ST_INSIDE]) {
        if (!(p->once && st[ST_FIRED])) scripts_start(p->on_exit, self);
        st[ST_FIRED] = 1;
    }
    st[ST_INSIDE] = inside;
}

void bhv_trigger_zone_on_touch(Actor *self, Actor *other, const void *params) {
    (void)params;
    if (other->category == CAT_PLAYER) bhv_state(self)[ST_TOUCHED] = 1;
}
