#include "render.hpp"
#include <cstdio>
#include "log.hpp"
#include "gfx.hpp"
#include "gte3d.hpp"
#include "input.hpp"
#include "util.hpp"
#include "world.hpp"
#include "assets/models.hpp"

namespace render {
namespace {
using world::g;

alignas(4) SVECTOR g_playerV[32];
gte3d::Face g_playerF[24];
gte3d::Mesh g_player{ .verts = g_playerV, .faces = g_playerF, .maxVerts = 32, .maxFaces = 24 };

constexpr int BALL_V = 2 + assets::BALL_SEG * (assets::BALL_RINGS - 1);
constexpr int BALL_F = assets::BALL_SEG * assets::BALL_RINGS;
alignas(4) SVECTOR g_ballV[BALL_V];
gte3d::Face g_ballF[BALL_F];
gte3d::Mesh g_ball{ .verts = g_ballV, .faces = g_ballF, .maxVerts = BALL_V, .maxFaces = BALL_F };

// Blob shadow under an object whose lowest point is `height` above the floor. It lands on the
// floor or on the highest box top below; it shrinks as the object gets higher.
void shadow(int x, int z, int height, int radius) {
    int box;
    const int ground = world::groundBelow(x, z, height, &box);
    const int above = util::clamp(height - ground, 0, 600);
    const int r = radius - radius * above / 900;
    int slot = gte3d::SHADOW_SLOT;
    if (box >= 0) {   // on a box top: sort just in front of that top face
        const world::Box& b = g.boxes[box];
        slot = util::max(gte3d::slotAt((b.x0 + b.x1) / 2, -b.top, (b.z0 + b.z1) / 2) - 1, 0);
    }
    gte3d::drawShadow(x, -ground - 1, z, r, slot);
}

// On-screen pad tester: every button lights up while held (bottom-right corner).
struct PadKey { uint16_t mask; int16_t x, y, w, h; uint8_t r, g, b; };
constexpr int PX = 206, PY = 192;
constexpr PadKey PAD_KEYS[] = {
    {PAD_L2, PX + 8, PY + 3, 22, 5, 250, 210, 80},   {PAD_L1, PX + 8, PY + 10, 22, 5, 250, 210, 80},
    {PAD_R2, PX + 76, PY + 3, 22, 5, 250, 210, 80},  {PAD_R1, PX + 76, PY + 10, 22, 5, 250, 210, 80},
    {PAD_UP, PX + 16, PY + 18, 7, 7, 255, 255, 255}, {PAD_DOWN, PX + 16, PY + 32, 7, 7, 255, 255, 255},
    {PAD_LEFT, PX + 9, PY + 25, 7, 7, 255, 255, 255}, {PAD_RIGHT, PX + 23, PY + 25, 7, 7, 255, 255, 255},
    {PAD_SELECT, PX + 40, PY + 27, 10, 4, 255, 255, 255}, {PAD_START, PX + 56, PY + 27, 10, 4, 255, 255, 255},
    {PAD_TRIANGLE, PX + 83, PY + 18, 7, 7, 64, 230, 170}, {PAD_CROSS, PX + 83, PY + 32, 7, 7, 120, 160, 255},
    {PAD_SQUARE, PX + 76, PY + 25, 7, 7, 255, 130, 220},  {PAD_CIRCLE, PX + 90, PY + 25, 7, 7, 255, 90, 90},
};

void padTester() {
    for (const PadKey& k : PAD_KEYS) {
        if (input::held(0, k.mask)) gfx::rect(k.x, k.y, k.w, k.h, k.r, k.g, k.b, 1);
        else gfx::rect(k.x, k.y, k.w, k.h, 40 + k.r / 6, 40 + k.g / 6, 40 + k.b / 6, 1);
    }
    gfx::rect(PX, PY, 106, 44, 16, 18, 30, 2);
}

constexpr const char* HELP[] = {
    "         - PAUSED -",
    "",
    "D-PAD    MOVE (CAMERA RELATIVE)",
    "CROSS    JUMP (HOLD = HIGHER)",
    "SQUARE   THROW A BALL",
    "CIRCLE   KICK NEARBY BALLS",
    "TRIANGLE CAMERA MODE",
    "L1 / R1  ORBIT CAMERA",
    "L2 / R2  ZOOM IN / OUT",
    "SELECT   RESET SCENE",
    "START    RESUME",
};
}  // namespace

void init() {
    for (const assets::ModelBox& b : assets::PLAYER_BOXES)
        gte3d::addBox(g_player, b.x0, b.y0, b.z0, b.x1, b.y1, b.z1, b.color, b.front);
    gte3d::addSphere(g_ball, world::BALL_R, assets::BALL_SEG, assets::BALL_RINGS);
    gte3d::setFloor(-world::ARENA, -world::ARENA, assets::FLOOR_TILE,
                    2 * world::ARENA / assets::FLOOR_TILE, 2 * world::ARENA / assets::FLOOR_TILE);
    dbg::log("MESHES player=%dv/%df r=%d ball=%dv/%df r=%d\n", g_player.numVerts, g_player.numFaces,
                g_player.radius, g_ball.numVerts, g_ball.numFaces, g_ball.radius);
}

void scene() {
    using namespace assets;
    const world::Camera& cam = g.cam;
    gte3d::lookAt(cam.eye, cam.at);

    // Sky above the horizon, plain below it (2D layer 15, behind the 3D band).
    const int horizon = gfx::SCREEN_H / 2 - gte3d::SCREEN_DIST * isin(cam.pitch) / icos(cam.pitch);
    if (horizon > 0)
        gfx::vgradient(0, 0, gfx::SCREEN_W, util::min(horizon, gfx::SCREEN_H), SKY_TOP.r, SKY_TOP.g,
                       SKY_TOP.b, SKY_LOW.r, SKY_LOW.g, SKY_LOW.b, 15);
    const int groundY = util::clamp(horizon, 0, gfx::SCREEN_H);
    if (groundY < gfx::SCREEN_H)
        gfx::rect(0, groundY, gfx::SCREEN_W, gfx::SCREEN_H - groundY, PLAIN.r, PLAIN.g, PLAIN.b, 15);

    gte3d::drawFloor(FLOOR_A, FLOOR_B, PLAIN, FOG_START);
    for (int i = 0; i < g.numBoxes; i++) {
        const world::Box& b = g.boxes[i];
        gte3d::drawBox(b.x0, -b.top, b.z0, b.x1, -b.bottom, b.z1, BOX_COLORS[b.color]);
    }

    const world::Player& p = g.player;
    const VECTOR pp = { p.pos.x.toInt(), p.pos.y.toInt(), p.pos.z.toInt() };
    const SVECTOR pr = { 0, int16_t(p.yaw), 0, 0 };
    gte3d::drawMesh(g_player, pp, pr, PLAYER_COLORS);
    shadow(pp.vx, pp.vz, -pp.vy, 30);

    for (int i = 0; i < world::MAX_BALLS; i++) {
        const world::Ball& b = g.balls[i];
        if (!b.active) continue;
        const VECTOR bp = { b.pos.x.toInt(), b.pos.y.toInt(), b.pos.z.toInt() };
        const SVECTOR br = { int16_t(b.spinX), 0, int16_t(b.spinZ), 0 };
        gte3d::drawMesh(g_ball, bp, br, BALL_COLORS[i]);
        shadow(bp.vx, bp.vz, -bp.vy - world::BALL_R, 34);
    }
}

void hud(const HudInfo& h) {
    char buf[64];
    int active = 0;
    for (const world::Ball& b : g.balls) active += b.active ? 1 : 0;
    std::snprintf(buf, sizeof(buf), "3D DEMO  FPS %d  POLYS %d", h.fps, gte3d::facesDrawn());
    gfx::text(8, 8, buf);
    std::snprintf(buf, sizeof(buf), "CAM %s  DIST %d", world::camModeName(g.cam.mode), g.cam.distGoal);
    gfx::text(8, 18, buf);
    std::snprintf(buf, sizeof(buf), "BALLS %d/%d  HEIGHT %d", active, world::MAX_BALLS, -g.player.pos.y.toInt());
    gfx::text(8, 28, buf);
    gfx::text(8, 224, "START: PAUSE + HELP");
    padTester();

    if (h.paused) {
        for (int i = 0; i < int(sizeof(HELP) / sizeof(HELP[0])); i++) gfx::text(36, 66 + i * 10, HELP[i]);
        gfx::rect(24, 56, 272, 126, 12, 14, 28, 3);
    }
    if (h.noPad) {
        gfx::text(88, 112, "CONNECT CONTROLLER");
        gfx::rect(76, 104, 168, 24, 120, 30, 30, 3);
    }
}
}  // namespace render
