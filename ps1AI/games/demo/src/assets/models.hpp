#pragma once
// Text assets for the 3D demo: colors, level layout and the player model (all built at boot).
#include <psxgte.h>
#include "world.hpp"

namespace assets {
// ---- Box colors (index = world::Box::color) -------------------------------------------
enum : uint8_t { C_WALL, C_SAND, C_ORANGE, C_RED, C_BLUE, C_PURPLE, C_TEAL, C_COUNT };
constexpr CVECTOR BOX_COLORS[C_COUNT] = {
    {150, 150, 165, 0},   // wall: light stone grey
    {222, 196, 140, 0},   // stair 1: sand
    {230, 150, 70, 0},    // stair 2: orange
    {205, 80, 70, 0},     // stair 3: brick red
    {90, 140, 230, 0},    // floating platform: sky blue
    {150, 100, 190, 0},   // pillar: purple
    {70, 180, 170, 0},    // low block: teal
};

// ---- Floor: 16x16 checkerboard of 128-unit tiles, fading to the plain color far away ----
constexpr int FLOOR_TILE = 128;
constexpr CVECTOR FLOOR_A   = {96, 168, 96, 0};
constexpr CVECTOR FLOOR_B   = {72, 140, 80, 0};
constexpr CVECTOR PLAIN     = {64, 104, 72, 0};    // distant ground (2D, behind the arena)
constexpr CVECTOR SKY_TOP   = {40, 70, 150, 0};
constexpr CVECTOR SKY_LOW   = {170, 200, 235, 0};
constexpr int     FOG_START = 1400;

// ---- Obstacles: x0, z0, x1, z1, bottom, top, color ---------------------------------------
// A 3-step staircase (50/105/160 high: each step is reachable with one jump, peak ~130),
// a floating platform next to the top step (you can walk under it and bump your head),
// a tall pillar and a low wide block. Walls around the arena are added by world::init().
constexpr world::Box OBSTACLES[] = {
    {-760, 160, -560, 360, 0, 50, C_SAND},
    {-760, 360, -560, 560, 0, 105, C_ORANGE},
    {-760, 560, -560, 760, 0, 160, C_RED},
    {-520, 560, -300, 760, 150, 176, C_BLUE},
    {300, 300, 400, 400, 0, 300, C_PURPLE},
    {250, -560, 650, -380, 0, 60, C_TEAL},
};
constexpr int WALL_H = 64, WALL_T = 32, WALL_SEGMENTS = 8;   // per side, so no face is huge

// ---- Player: a small robot, 4 boxes, facing +Z (rotated by its yaw) ----------------------
// Legs (dark blue), torso (red) with a lighter chest plate on the front, head (white) with a
// cyan visor on the front so the facing direction is obvious. Feet at y = 0, head top y = -122.
enum : uint8_t { P_LEGS, P_TORSO, P_CHEST, P_HEAD, P_VISOR, P_COUNT };
constexpr CVECTOR PLAYER_COLORS[P_COUNT] = {
    {50, 60, 140, 0}, {210, 50, 50, 0}, {250, 130, 110, 0}, {235, 235, 235, 0}, {60, 220, 240, 0},
};
struct ModelBox { int16_t x0, y0, z0, x1, y1, z1; uint8_t color, front; };
constexpr ModelBox PLAYER_BOXES[] = {
    {-22, -44, -10, -6, 0, 10, P_LEGS, P_LEGS},
    {6, -44, -10, 22, 0, 10, P_LEGS, P_LEGS},
    {-26, -92, -16, 26, -44, 16, P_TORSO, P_CHEST},
    {-18, -122, -18, 18, -94, 18, P_HEAD, P_VISOR},
};

// ---- Balls: beach balls (8 segments x 4 rings), two stripe colors each --------------------
constexpr int BALL_SEG = 8, BALL_RINGS = 4;
constexpr CVECTOR BALL_COLORS[world::MAX_BALLS][2] = {
    {{240, 60, 60, 0}, {245, 245, 245, 0}},
    {{60, 110, 240, 0}, {250, 220, 60, 0}},
    {{60, 200, 90, 0}, {245, 245, 245, 0}},
    {{250, 150, 40, 0}, {150, 70, 200, 0}},
    {{240, 90, 180, 0}, {245, 245, 245, 0}},
    {{40, 200, 220, 0}, {240, 60, 60, 0}},
    {{250, 230, 70, 0}, {60, 60, 70, 0}},
    {{160, 100, 60, 0}, {245, 245, 245, 0}},
};

// ---- Start layout -------------------------------------------------------------------------
constexpr int PLAYER_START_X = 0, PLAYER_START_Z = -300;
struct BallStart { int16_t x, h, z, vx, vz; };     // h = height of the centre above the floor
constexpr BallStart BALL_STARTS[] = {
    {-160, 260, 40, 2, 0},
    {60, 380, 160, 0, -1},
    {250, 500, -40, -1, 1},
};
}  // namespace assets
