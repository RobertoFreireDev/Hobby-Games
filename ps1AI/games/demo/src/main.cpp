// 3D playground: walk, jump and climb, throw and kick bouncing balls, orbit/zoom the camera.
// Exercises every pad button, the GTE renderer (engine/gte3d) and fixed-point physics.
#include <cstdio>
#include <psxgpu.h>
#include "gfx.hpp"
#include "input.hpp"
#include "audio.hpp"
#include "gte3d.hpp"
#include "util.hpp"
#include "world.hpp"
#include "render.hpp"
#include "sounds.hpp"
#include "log.hpp"

namespace {
struct ButtonName { uint16_t mask; const char* name; };
constexpr ButtonName BUTTONS[] = {
    {PAD_UP, "UP"}, {PAD_DOWN, "DOWN"}, {PAD_LEFT, "LEFT"}, {PAD_RIGHT, "RIGHT"},
    {PAD_CROSS, "CROSS"}, {PAD_CIRCLE, "CIRCLE"}, {PAD_SQUARE, "SQUARE"}, {PAD_TRIANGLE, "TRIANGLE"},
    {PAD_L1, "L1"}, {PAD_L2, "L2"}, {PAD_R1, "R1"}, {PAD_R2, "R2"},
    {PAD_START, "START"}, {PAD_SELECT, "SELECT"},
};

int axis(uint16_t minus, uint16_t plus) {
    return (input::held(0, plus) ? 1 : 0) - (input::held(0, minus) ? 1 : 0);
}

world::Controls readControls() {
    world::Controls c;
    c.moveX         = axis(PAD_LEFT, PAD_RIGHT);
    c.moveZ         = axis(PAD_DOWN, PAD_UP);
    c.jump          = input::pressed(0, PAD_CROSS);
    c.jumpHeld      = input::held(0, PAD_CROSS);
    c.throwBall     = input::pressed(0, PAD_SQUARE);
    c.kick          = input::pressed(0, PAD_CIRCLE);
    c.orbit         = axis(PAD_L1, PAD_R1);
    c.zoom          = axis(PAD_L2, PAD_R2);
    c.nextCamMode   = input::pressed(0, PAD_TRIANGLE);
    c.orbitReleased = input::released(0, PAD_L1) || input::released(0, PAD_R1);
    c.zoomReleased  = input::released(0, PAD_L2) || input::released(0, PAD_R2);
    return c;
}
}  // namespace

int main() {
    gfx::init(64, 104, 72);
    input::init();
    audio::init();
    gte3d::init();
    world::init();
    render::init();
    dbg::log("BOOT OK\n");

    bool paused = false;
    int fps = 60, fpsFrames = 0, lastVb = VSync(-1);
    for (;;) {
        input::update();
        audio::update();
        world::State& g = world::g;
        const bool padOk = input::connected(0);
        for (const ButtonName& b : BUTTONS)
            if (input::pressed(0, b.mask)) dbg::log("PRESS %s frame=%d\n", b.name, g.frame);

        world::Controls c;
        if (padOk) {
            if (input::pressed(0, PAD_START)) {
                paused = !paused;
                sfx::ui();
                dbg::log("PAUSE frame=%d on=%d\n", g.frame, paused ? 1 : 0);
            }
            if (input::pressed(0, PAD_SELECT)) { world::reset(); sfx::reset(); }
            if (!paused) c = readControls();
        }
        // VSync(1) = scanlines since the last VBlank: CPU time used so far this frame (263 = 1 frame).
        const int t0 = VSync(1);
        if (!paused) world::step(c);       // without a pad the balls keep bouncing
        world::updateCamera(c);
        const int t1 = VSync(1);
        render::scene();
        render::hud({fps, paused, !padOk});
        const int t2 = VSync(1);
        const int faces = gte3d::facesDrawn(), bytes = gfx::primBytes();
        gfx::flip();

        if (++fpsFrames == 60) {           // VSync(-1) = VBlank counter
            const int vb = VSync(-1);
            fps = 3600 / util::max(vb - lastVb, 1);
            lastVb = vb;
            fpsFrames = 0;
        }
        if (g.frame % 120 == 0) {
            const world::Player& p = g.player;
            int active = 0;
            for (const world::Ball& b : g.balls) active += b.active ? 1 : 0;
            dbg::log("STATE frame=%d pos=%d,%d,%d ground=%d yaw=%d cam=%s camyaw=%d dist=%d balls=%d resting=%d"
                        " fps=%d polys=%d bytes=%d lines=%d+%d\n",
                        g.frame, p.pos.x.toInt(), -p.pos.y.toInt(), p.pos.z.toInt(), p.onGround ? 1 : 0, p.yaw,
                        world::camModeName(g.cam.mode), g.cam.yaw, g.cam.dist, active, world::restingBalls(),
                        fps, faces, bytes, t1 - t0, t2 - t1);
        }
        g.frame++;
    }
}
