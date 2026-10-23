// scene.c - load / unload scenes, spawn their instances, screen fades.
#include <tonc_memmap.h>
#include <tonc_memdef.h>
#include "scene.h"
#include "core.h"
#include "actor.h"
#include "actions.h"
#include "anim.h"
#include "particles.h"
#include "camera.h"
#include "bg.h"
#include "sprites.h"
#include "shiny.h"
#include "audio.h"
#include "ui.h"
#include "floattext.h"
#include "vars.h"

static const SceneData *s_scene;
static s16 s_scene_node = -1;
static s16 s_pending = -1;
static u16 s_loads;         // scenes (and screens of a screens-camera scene) loaded so far
static s16 s_room = -1;     // screens camera: the screen showing (-1 = none yet / no screens)

static fixed s_fade;        // 0 = clear, 16 << 8 = black
static fixed s_fade_step;
static fixed s_fade_target;
static fixed s_flash;       // > 0: the screen is lit up white (16 << 8 = fully white)
static fixed s_flash_step;

const SceneData *scene_current(void) { return s_scene; }
s16 scene_current_node(void) { return s_scene_node; }
u16 scene_loads(void) { return s_loads; }
s16 scene_screen(void) { return s_room; }

int scene_screen_box(s32 *x, s32 *y) {
    if (!s_scene || !s_scene->screens || s_room < 0) return 0;
    s32 row = 0, col = s_room;
    while (col >= s_scene->screen_cols) { col -= s_scene->screen_cols; row++; }
    *x = col * 240;
    *y = row * 160;
    return 1;
}

void scene_goto(s16 node) {
    if (node >= 0 && node < NODE_COUNT && g_nodes[node].type == NT_SCENE) s_pending = node;
}

void scene_fade(int to_black, int ticks) {
    s_fade_target = to_black ? fx_from_int(16) : 0;
    if (ticks <= 0) {
        s_fade = s_fade_target;
        s_fade_step = 0;
        return;
    }
    if (!to_black && s_fade == 0) s_fade = fx_from_int(16);   // fade_in always starts from black
    s_fade_step = fx_from_int(16) / ticks;
    if (s_fade_step == 0) s_fade_step = 1;
}

void scene_flash(int ticks) {
    s_flash = fx_from_int(16);
    s_flash_step = fx_from_int(16) / (ticks > 0 ? ticks : 1);
    if (s_flash_step == 0) s_flash_step = 1;
}

void scene_vblank(void) {
    if (s_flash > 0) {
        REG_BLDCNT = BLD_BUILD(BLD_ALL | BLD_BACKDROP, 0, 2);  // mode 2 = fade to white
        REG_BLDY = (u16)fx_to_int(s_flash);
        return;
    }
    REG_BLDCNT = BLD_BUILD(BLD_ALL | BLD_BACKDROP, 0, 3);      // mode 3 = fade to black
    REG_BLDY = (u16)fx_to_int(s_fade);
}

Actor *scene_spawn(s16 node, s32 x, s32 y) {
    if (node < 0 || node >= NODE_COUNT) return NULL;
    const NodeEntry *e = &g_nodes[node];
    if (e->type == NT_PARTICLE) {
        particles_burst((const ParticleData *)e->data, x, y);
        return NULL;
    }
    if (e->type < NT_PLAYER || e->type > NT_TRIGGER) return NULL;
    const ActorData *ad = (const ActorData *)e->data;
    return actor_spawn(node, x, y, ad->logic, ad->logic_count, -1);
}

// What an instance places: its object, or the variant its variable picks (a world's map).
static const void *instance_data(const InstanceData *in) {
    if (!in->pick_count) return in->data;
    s32 k = vars_get(in->pick_var);
    if (k < 0) k = 0;
    if (k >= in->pick_count) k = in->pick_count - 1;
    return in->picks[k];
}

// Place instance i of the scene. Returns the actor it made (NULL for anything else).
static Actor *place(const SceneData *sc, int i) {
    const InstanceData *in = &sc->instances[i];
    switch (in->kind) {
    case INST_TILEMAP:  bg_set_layer((const TilemapData *)instance_data(in)); break;
    case INST_HUD:      ui_show_hud((const HudData *)in->data); break;
    case INST_MENU:     ui_open_menu((const MenuData *)in->data); break;
    case INST_DIALOG:   ui_show_dialog((const DialogData *)in->data); break;
    case INST_PARTICLE: particles_place((const ParticleData *)in->data, in->x, in->y); break;
    case INST_ACTOR:    return actor_spawn(in->node, in->x, in->y, in->logic, in->logic_count, (s16)i);
    }
    return NULL;
}

void scene_enter_screen(s16 col, s16 row) {
    const SceneData *sc = s_scene;
    if (!sc || !sc->screens) return;
    s16 screen = (s16)(row * sc->screen_cols + col);
    if (screen == s_room) return;
    if (s_room >= 0) {
        // Leaving a screen: all of its things go, the players stay (the maps and the HUD too).
        for (int i = 0; i < MAX_ACTORS; i++)
            if (g_actors[i].active && g_actors[i].type != NT_PLAYER) actor_destroy(&g_actors[i]);
        particles_clear();
        ftext_reset();
        sprites_reset();            // OBJ VRAM and palettes are handed out again for the new screen
        s_loads++;                  // ground zones and the monsters' crowd lists start over
    }
    s_room = screen;
    if (sc->screen_var >= 0) vars_set(sc->screen_var, screen);
    scripts_start(sc->on_screen, NULL);         // first: its things check what it sets (appear_if)
    for (int i = 0; i < sc->instance_count; i++)
        if (sc->instances[i].room == screen) place(sc, i);
}

static void load_scene(s16 node) {
    const SceneData *sc = (const SceneData *)g_nodes[node].data;
    // Unload everything from the previous scene.
    scripts_clear();
    actor_clear_all();
    particles_clear();
    ftext_reset();
    ui_reset();
    sprites_reset();
    shiny_reset();
    bg_reset(sc->backdrop);
    s_scene = sc;
    s_scene_node = node;
    s_loads++;
    s_fade = 0;
    s_fade_step = 0;
    s_fade_target = 0;
    s_flash = 0;
    s_room = -1;

    camera_reset(sc->cam_x, sc->cam_y, sc->camera_bounds);

    // Place every instance, in order. A screens scene places the ones always there, but the actor
    // the camera follows and its screen's things come after on_start (which loads the save they check).
    Actor *follow = NULL;
    for (int i = 0; i < sc->instance_count; i++) {
        if (sc->instances[i].room >= 0 || (sc->screens && i == sc->camera_follow)) continue;
        Actor *a = place(sc, i);
        if (i == sc->camera_follow) follow = a;
    }

    if (follow) camera_set_target(follow);

    if (sc->music >= 0) audio_play_music((const MusicData *)g_nodes[sc->music].data);
    else audio_stop_music();

    scripts_start(sc->on_start, NULL);
    if (sc->on_start_fn) sc->on_start_fn();

    // A screens scene starts on the followed actor's screen, once on_start has set the variables
    // its things check when they appear (appear_if).
    if (sc->screens) {
        camera_set_screens(1);
        if (sc->camera_follow >= 0) {
            const InstanceData *f = &sc->instances[sc->camera_follow];
            Actor *a = place(sc, sc->camera_follow);
            if (a) camera_set_target(a);
            s32 y = f->y - 8;
            scene_enter_screen((s16)(f->x / 240), (s16)(y < 0 ? 0 : y / 160));
        }
    }

    camera_update();
    bg_refresh_all();
}

void scene_update(void) {
    if (s_pending >= 0) {
        s16 n = s_pending;
        s_pending = -1;
        load_scene(n);
    }
    if (s_fade != s_fade_target) {
        if (s_fade < s_fade_target) {
            s_fade += s_fade_step;
            if (s_fade > s_fade_target) s_fade = s_fade_target;
        } else {
            s_fade -= s_fade_step;
            if (s_fade < s_fade_target) s_fade = s_fade_target;
        }
    }
    if (s_flash > 0) s_flash -= s_flash_step;
    scripts_update();
    if (!core_paused()) {
        sprites_queue_clear();          // behaviors queue this frame's extra sprites again
        ftext_pins_clear();             // ... and pin their words again
        actor_update_all();
        if (s_scene && s_scene->on_update_fn) s_scene->on_update_fn();
    }
}
