// move_switch - something only a move of the right type changes: a bramble wall fire burns,
// flames water puts out. moves.c tells it when the effect of one of the player's moves touches
// it (the same picture test as a move hitting a monster); a move of one of its types counts a
// hit and after `hits` of them on_open runs, any other type runs on_wrong (a thud).
#include "move_switch.h"
#include "behavior_params.h"
#include "engine/actions.h"

enum { ST_HITS, ST_OPEN };

void bhv_move_switch_init(Actor *a, const void *params) {
    (void)params;
    u32 *st = bhv_state(a);
    st[ST_HITS] = 0;
    st[ST_OPEN] = 0;
}

void move_switch_touch(Actor *a, const MoveData *m) {
    int k = actor_logic_index(a, BHV_MOVE_SWITCH);
    if (k < 0 || !actor_alive(a)) return;
    const Params_move_switch *p = (const Params_move_switch *)a->logic[k].params;
    u32 *st = actor_state_of(a, k);
    if (st[ST_OPEN]) return;
    if (!(p->types & (1u << m->type))) {
        scripts_start(p->on_wrong, a);
        return;
    }
    if (++st[ST_HITS] < (u32)(p->hits > 0 ? p->hits : 1)) return;
    st[ST_OPEN] = 1;
    scripts_start(p->on_open, a);
}
