#pragma once
// 3D playground state and physics.
// World units: the player is ~120 tall, the arena floor spans -ARENA..ARENA on X and Z.
// Y points DOWN (GTE convention): floor y = 0, a box of height h has its top at y = -h.
// Angles: 4096 = 360 deg; yaw 0 faces +Z, yaw 1024 faces +X.
#include <cstdint>
#include <psxgte.h>
#include "fixed.hpp"

namespace world {
constexpr int ARENA     = 1024;      // half size of the floor inside the walls
constexpr int MAX_BALLS = 8;
constexpr int BALL_R    = 40;
constexpr int PLAYER_HW = 26;        // half width of the player's collision box (X and Z)
constexpr int PLAYER_H  = 122;       // collision box height (feet to head)
constexpr int MAX_BOXES = 48;

struct Box {                         // static AABB; heights are positive up (y = -height)
    int16_t x0, z0, x1, z1;
    int16_t bottom, top;
    uint8_t color;
};

struct Ball {
    Vec3 pos, vel;                   // pos = centre
    int  spinX = 0, spinZ = 0;       // rolling angles for drawing
    bool active = false;
};

struct Player {
    Vec3 pos, vel;                   // pos = centre of the feet
    int  yaw = 0;                    // facing
    bool onGround = false;
    int  jumpFrames = 0;             // frames since the jump started (for the variable jump)
};

enum class CamMode : uint8_t { ORBIT, FOLLOW, TOP, COUNT };

struct Camera {
    CamMode mode = CamMode::ORBIT;
    int yaw = 0, yawGoal = 0;        // camera looks along (sin yaw, cos yaw) on the floor
    int pitch = 0, dist = 0, distGoal = 0;
    Vec3 target;                     // smoothed look-at point
    VECTOR eye, at;                  // results for the renderer
};

struct Controls {                    // one frame of player intent, decoupled from the pad
    int  moveX = 0, moveZ = 0;       // d-pad: x -1 left / +1 right, z +1 up (away from camera)
    bool jump = false, jumpHeld = false, throwBall = false, kick = false;
    int  orbit = 0;                  // -1 L1 / +1 R1
    int  zoom = 0;                   // -1 L2 (closer) / +1 R2 (farther)
    bool nextCamMode = false;
    bool orbitReleased = false, zoomReleased = false;
};

struct State {
    Player player;
    Ball   balls[MAX_BALLS];
    int    nextBall = 0;
    Camera cam;
    Box    boxes[MAX_BOXES];         // walls first, then obstacles
    int    numBoxes = 0;
    int    firstObstacle = 0;        // physics skips the walls: the glass-wall clamp covers them
    int    frame = 0;
};

extern State g;

void init();                         // builds the level; call once after the engine init
void reset();                        // player, balls and camera back to the start
void step(const Controls& c);        // one 60 Hz tick of physics
void updateCamera(const Controls& c);
const char* camModeName(CamMode m);
int  groundBelow(int x, int z, int height, int* boxIndex);   // highest surface <= height under (x,z)
int  restingBalls();
}  // namespace world
