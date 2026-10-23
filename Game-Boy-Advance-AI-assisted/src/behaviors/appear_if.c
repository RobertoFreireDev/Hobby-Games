// appear_if - when it appears it checks a variable and, if the check fails, removes itself at
// once, unseen, before its other behaviors start: a gate until it is opened, a guard until its
// monster is freed, a sign once a mode is open. It checks again every tick and goes the moment the
// check fails (a trapped monster's vines once it is freed).
#include "appear_if.h"
#include "behavior_params.h"
#include "engine/vars.h"

// 'var op value' (or 'var op from'); op is the if_var comparison order (CMP_*).
static int passes(const Params_appear_if *p) {
    s32 v = vars_get(p->var), w = p->from >= 0 ? vars_get(p->from) : p->value;
    switch (p->op) {
    case CMP_EQ: return v == w;
    case CMP_NE: return v != w;
    case CMP_LT: return v < w;
    case CMP_LE: return v <= w;
    case CMP_GT: return v > w;
    case CMP_GE: return v >= w;
    }
    return 1;
}

void bhv_appear_if_init(Actor *a, const void *params) {
    if (!passes(params)) actor_destroy(a);
}

void bhv_appear_if_update(Actor *a, const void *params) {
    if (!passes(params)) actor_destroy(a);
}
