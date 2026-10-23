// topdown_controller - walk in any direction with the D-pad (no gravity). A monster walks at
// its species' pace and holds still while it can't act (paralyzed, frozen). With `enter_ticks`
// it first walks on its own toward `enter_dir` for that long (out of a cave), the D-pad ignored.
// With `solid_props` solid props (the menu map's signs) stop it like walls.
#include "topdown_controller.h"
#include "monster.h"
#include "behavior_params.h"
#include "engine/input.h"
#include "engine/vars.h"

// Letting go of a diagonal rarely lifts both buttons on the same frame: a straight direction
// that is half of the diagonal it faces turns it only after this many ticks, so it stops
// still facing the diagonal.
#define RELEASE_TICKS 5

#define ST_HALF 0           // ticks the D-pad has held half of the diagonal it faces
#define ST_ENTER 1          // ticks walked on its own since it appeared (enter_ticks)

void bhv_topdown_controller_init(Actor *a, const void *params) {
    const Params_topdown_controller *p = params;
    if (p->solid_props) a->collides |= 1u << CAT_PROP;  // after the monster behavior gave it its body
}

void bhv_topdown_controller_update(Actor *a, const void *params) {
    const Params_topdown_controller *p = params;
    u32 *st = bhv_state(a);
    int dx = input_dir_x(), dy = input_dir_y();
    if (st[ST_ENTER] < (u32)p->enter_ticks) {    // walking in on its own
        st[ST_ENTER]++;
        dx = p->enter_dir == TOPDOWN_CONTROLLER_ENTER_DIR_LEFT ? -1 : p->enter_dir == TOPDOWN_CONTROLLER_ENTER_DIR_RIGHT;
        dy = p->enter_dir == TOPDOWN_CONTROLLER_ENTER_DIR_UP ? -1 : p->enter_dir == TOPDOWN_CONTROLLER_ENTER_DIR_DOWN;
    }
    if (!p->eight_way && dx && dy) dy = 0;
    if (a->anim_lock) return;                   // being knocked back
    if (monster_species(a) && !monster_can_act(a)) {
        a->vx = a->vy = 0;
        actor_play_slot(a, ANIM_IDLE);
        return;
    }
    fixed speed = p->speed;
    if (p->speed_var >= 0) speed = fx_div100(speed * (100 + p->speed_step * vars_get(p->speed_var)));   // + speed_step % per point
    speed = monster_speed(a, speed);
    a->vx = dx * speed;
    a->vy = dy * speed;
    if (dx && dy) {                             // diagonal: same speed as straight (x 0.707)
        a->vx = a->vx * 181 / 256;
        a->vy = a->vy * 181 / 256;
    }
    int half = a->look_x && a->look_y && (!dx || !dy) && (dx == a->look_x || dy == a->look_y);
    if (half && st[ST_HALF] < RELEASE_TICKS) st[ST_HALF]++;
    else {
        st[ST_HALF] = 0;
        actor_face(a, dx, dy);                  // picks the animations for the 8 ways
    }
    actor_play_slot(a, (dx || dy) ? ANIM_WALK : ANIM_IDLE);
}
