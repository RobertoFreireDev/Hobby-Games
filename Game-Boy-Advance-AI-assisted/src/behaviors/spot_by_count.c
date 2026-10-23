// spot_by_count - when it appears, a count variable (how many monsters are unlocked) picks
// where it stands: spot k of its list for count = need + k (past the end = the last one), as
// pixels from where it was placed, and it shows its animation k x `frames` frames later in its
// sprite sheet (the same animation drawn for that spot: lit from another side). Below `need`
// it stays hidden. The intro's monsters take their seats around the fire this way. With
// `shiny_var` set and its `shiny_slot` flag on, it shimmers through the rainbow (a shiny monster).
#include "spot_by_count.h"
#include "behavior_params.h"
#include "engine/shiny.h"
#include "engine/vars.h"

void bhv_spot_by_count_init(Actor *a, const void *params) {
    const Params_spot_by_count *p = params;
    s32 k = vars_get(p->var) - p->need;
    if (k < 0) {
        a->flags |= ACTOR_HIDDEN;
        return;
    }
    if (p->spots.count) {
        if (k >= p->spots.count) k = p->spots.count - 1;
        s32 x = a->home_x + p->spots.xy[2 * k], y = a->home_y + p->spots.xy[2 * k + 1];
        a->x = a->prev_x = fx_from_int(x);
        a->y = a->prev_y = fx_from_int(y);
        a->home_x = x;
        a->home_y = y;
    }
    a->frame_shift = (u8)(k * p->frames);
    if (p->shiny_var >= 0 && vars_get(vars_slot(p->shiny_var, p->shiny_slot)) && a->body) {
        const AnimationData *an = a->body->anims[a->body->default_slot];
        const PaletteData *sh = shiny_palette(a->pal ? a->pal : an ? an->sprite->palette : NULL);
        if (sh) a->pal = sh;
    }
}
