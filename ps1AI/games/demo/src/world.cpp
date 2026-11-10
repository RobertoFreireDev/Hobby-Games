#include "world.hpp"
#include <cstdio>
#include "log.hpp"
#include "assets/models.hpp"
#include "sounds.hpp"
#include "util.hpp"

namespace world {
State g;

namespace {
// ---- Tuning (units per frame at 60 Hz) ------------------------------------------------
constexpr fx GRAVITY  = 0.6_fx;
constexpr fx MAX_FALL = 18_fx;
constexpr fx JUMP_V   = 12.5_fx;      // peak = v^2 / 2g ~ 130 units
constexpr fx JUMP_CUT = 4_fx;         // releasing X early caps the rising speed (short hop)
constexpr fx ACCEL_GROUND = 1.5_fx, FRICTION_GROUND = 0.78_fx;   // top speed ~5.3
constexpr fx ACCEL_AIR    = 0.4_fx, FRICTION_AIR    = 0.94_fx;
constexpr fx BALL_E_FLOOR = 0.72_fx, BALL_E_BOX = 0.75_fx, BALL_E_BALL = 0.92_fx, BALL_E_PLAYER = 0.5_fx;
constexpr fx BALL_ROLL = 0.985_fx, BALL_DRAG = 0.998_fx;
constexpr fx REST_SPEED  = 1.3_fx;    // slower impacts do not bounce (resting contact)
constexpr fx SOUND_SPEED = 2_fx;      // slower impacts are silent
constexpr int KICK_RANGE = 130;
constexpr int CAM_DIST_MIN = 320, CAM_DIST_MAX = 1300;
constexpr int CHEST = 70;             // camera looks at the player's chest

constexpr fx F(int i) { return fx::fromInt(i); }
fx clampFx(fx v, fx lo, fx hi) { return v < lo ? lo : (hi < v ? hi : v); }
Vec3 facing(int yaw) { return { fx::fromRaw(isin(yaw)), 0_fx, fx::fromRaw(icos(yaw)) }; }

// Player box vs static box, strict (touching surfaces do not overlap).
bool overlaps(const Box& b, const Vec3& p) {
    return p.x > F(b.x0 - PLAYER_HW) && p.x < F(b.x1 + PLAYER_HW) &&
           p.z > F(b.z0 - PLAYER_HW) && p.z < F(b.z1 + PLAYER_HW) &&
           p.y > F(-b.top) && p.y - F(PLAYER_H) < F(-b.bottom);
}

// Unit normal (fx) of an offset given in 1/16 units with length `len` (also 1/16 units).
Vec3 normalOf(int dx, int dy, int dz, int len) {
    return { fx::fromRaw(dx * 4096 / len), fx::fromRaw(dy * 4096 / len), fx::fromRaw(dz * 4096 / len) };
}

// Bounce velocity `vel` off a surface with normal n moving at surfVel. Returns the impact speed.
fx bounce(Vec3& vel, const Vec3& n, const Vec3& surfVel, fx e) {
    const fx vn = (vel - surfVel).dot(n);
    if (vn >= 0_fx) return 0_fx;                       // already separating
    const fx k = (-vn < REST_SPEED) ? 1_fx : 1_fx + e; // tiny impacts just stop
    vel -= n * (vn * k);
    return -vn;
}

// Sphere vs AABB (y0 < y1): pushes the sphere out and bounces it. Returns the impact speed.
fx sphereVsBox(Vec3& pos, Vec3& vel, int r, int x0, int y0, int z0, int x1, int y1, int z1,
               fx e, const Vec3& surfVel) {
    const fx R = F(r);
    if (pos.x <= F(x0) - R || pos.x >= F(x1) + R || pos.y <= F(y0) - R || pos.y >= F(y1) + R ||
        pos.z <= F(z0) - R || pos.z >= F(z1) + R)
        return 0_fx;
    const Vec3 c = { clampFx(pos.x, F(x0), F(x1)), clampFx(pos.y, F(y0), F(y1)), clampFx(pos.z, F(z0), F(z1)) };
    const int dx = (pos.x - c.x).raw >> 8, dy = (pos.y - c.y).raw >> 8, dz = (pos.z - c.z).raw >> 8;
    const int d2 = dx * dx + dy * dy + dz * dz, r16 = r * 16;
    if (d2 >= r16 * r16) return 0_fx;
    Vec3 n;
    fx push;
    if (d2 == 0) {                                     // centre inside: leave through the nearest face
        const fx pen[6] = { pos.x - F(x0), F(x1) - pos.x, pos.y - F(y0), F(y1) - pos.y, pos.z - F(z0), F(z1) - pos.z };
        int best = 0;
        for (int i = 1; i < 6; i++) if (pen[i] < pen[best]) best = i;
        const fx one = (best & 1) ? 1_fx : -1_fx;
        n = { best / 2 == 0 ? one : 0_fx, best / 2 == 1 ? one : 0_fx, best / 2 == 2 ? one : 0_fx };
        push = pen[best] + R;
    } else {
        const int dist = SquareRoot0(d2);
        n = normalOf(dx, dy, dz, dist);
        push = fx::fromRaw((r16 - dist) << 8);
    }
    pos += n * push;
    return bounce(vel, n, surfVel, e);
}

void stepPlayer(const Controls& c) {
    Player& p = g.player;
    if (c.moveX || c.moveZ) {
        // D-pad direction relative to the camera: up 0, right 1024, down 2048, left 3072.
        static constexpr int16_t DIR[3][3] = {          // [moveZ + 1][moveX + 1]
            {2560, 2048, 1536}, {3072, 0, 1024}, {3584, 0, 512},
        };
        const int target = (g.cam.yaw + DIR[c.moveZ + 1][c.moveX + 1]) & 4095;
        const int diff = util::angleDiff(p.yaw, target);
        const int turn = util::clamp(diff / 4, -160, 160);
        p.yaw = (p.yaw + (turn ? turn : diff)) & 4095;
        const fx accel = p.onGround ? ACCEL_GROUND : ACCEL_AIR;
        p.vel.x += fx::fromRaw(isin(target)) * accel;
        p.vel.z += fx::fromRaw(icos(target)) * accel;
    }
    const fx fr = p.onGround ? FRICTION_GROUND : FRICTION_AIR;
    p.vel.x = p.vel.x * fr;
    p.vel.z = p.vel.z * fr;

    if (c.jump && p.onGround) {
        p.vel.y = -JUMP_V;
        p.onGround = false;
        p.jumpFrames = 1;
        sfx::jump();
        dbg::log("JUMP frame=%d x=%d z=%d h=%d\n", g.frame, p.pos.x.toInt(), p.pos.z.toInt(), -p.pos.y.toInt());
    }
    if (!c.jumpHeld && p.vel.y < -JUMP_CUT) p.vel.y = -JUMP_CUT;   // variable jump height
    p.vel.y = util::min(p.vel.y + GRAVITY, MAX_FALL);

    const bool wasOnGround = p.onGround;
    const fx fallSpeed = p.vel.y;
    // Move one axis at a time and push out of boxes along that axis.
    p.pos.x += p.vel.x;
    for (int i = g.firstObstacle; i < g.numBoxes; i++) {
        const Box& b = g.boxes[i];
        if (!overlaps(b, p.pos)) continue;
        p.pos.x = p.vel.x > 0_fx ? F(b.x0 - PLAYER_HW) : F(b.x1 + PLAYER_HW);
        p.vel.x = 0_fx;
    }
    p.pos.z += p.vel.z;
    for (int i = g.firstObstacle; i < g.numBoxes; i++) {
        const Box& b = g.boxes[i];
        if (!overlaps(b, p.pos)) continue;
        p.pos.z = p.vel.z > 0_fx ? F(b.z0 - PLAYER_HW) : F(b.z1 + PLAYER_HW);
        p.vel.z = 0_fx;
    }
    p.pos.y += p.vel.y;
    p.onGround = false;
    for (int i = g.firstObstacle; i < g.numBoxes; i++) {
        const Box& b = g.boxes[i];
        if (!overlaps(b, p.pos)) continue;
        if (p.vel.y >= 0_fx) {                       // falling: land on top
            p.pos.y = F(-b.top);
            p.onGround = true;
        } else {                                     // rising: bump the head on the bottom
            p.pos.y = F(PLAYER_H - b.bottom);
            sfx::headBump();
            dbg::log("HEADBUMP frame=%d box=%d\n", g.frame, i);
        }
        p.vel.y = 0_fx;
    }
    if (p.pos.y >= 0_fx) { p.pos.y = 0_fx; p.vel.y = 0_fx; p.onGround = true; }
    // Glass walls: never leave the arena, even when jumping above the low walls.
    const fx lim = F(ARENA - PLAYER_HW);
    if (p.pos.x > lim)  { p.pos.x = lim;  p.vel.x = 0_fx; }
    if (p.pos.x < -lim) { p.pos.x = -lim; p.vel.x = 0_fx; }
    if (p.pos.z > lim)  { p.pos.z = lim;  p.vel.z = 0_fx; }
    if (p.pos.z < -lim) { p.pos.z = -lim; p.vel.z = 0_fx; }

    if (p.onGround && !wasOnGround) {
        sfx::land(fallSpeed.toInt());
        dbg::log("LAND frame=%d h=%d x=%d z=%d\n", g.frame, -p.pos.y.toInt(), p.pos.x.toInt(), p.pos.z.toInt());
    }
}

void stepBall(int i) {
    Ball& b = g.balls[i];
    b.vel.y = util::min(b.vel.y + GRAVITY, MAX_FALL);
    b.pos += b.vel;
    fx impact = 0_fx;
    bool rolling = false;
    if (b.pos.y > F(-BALL_R)) {                       // floor
        b.pos.y = F(-BALL_R);
        impact = bounce(b.vel, {0_fx, -1_fx, 0_fx}, {}, BALL_E_FLOOR);
        rolling = true;
    }
    const fx lim = F(ARENA - BALL_R);                 // glass walls
    if (b.pos.x > lim)  { b.pos.x = lim;  impact = util::max(impact, bounce(b.vel, {-1_fx, 0_fx, 0_fx}, {}, BALL_E_BOX)); }
    if (b.pos.x < -lim) { b.pos.x = -lim; impact = util::max(impact, bounce(b.vel, {1_fx, 0_fx, 0_fx}, {}, BALL_E_BOX)); }
    if (b.pos.z > lim)  { b.pos.z = lim;  impact = util::max(impact, bounce(b.vel, {0_fx, 0_fx, -1_fx}, {}, BALL_E_BOX)); }
    if (b.pos.z < -lim) { b.pos.z = -lim; impact = util::max(impact, bounce(b.vel, {0_fx, 0_fx, 1_fx}, {}, BALL_E_BOX)); }
    for (int k = g.firstObstacle; k < g.numBoxes; k++) {
        const Box& o = g.boxes[k];
        const fx hit = sphereVsBox(b.pos, b.vel, BALL_R, o.x0, -o.top, o.z0, o.x1, -o.bottom, o.z1, BALL_E_BOX, {});
        if (hit > 0_fx && b.pos.y <= F(-o.top - BALL_R + 2)) rolling = true;   // resting on top
        impact = util::max(impact, hit);
    }
    const Player& p = g.player;                       // the player is a moving, unmovable box
    impact = util::max(impact, sphereVsBox(b.pos, b.vel, BALL_R,
        (p.pos.x - F(PLAYER_HW)).toInt(), (p.pos.y - F(PLAYER_H)).toInt(), (p.pos.z - F(PLAYER_HW)).toInt(),
        (p.pos.x + F(PLAYER_HW)).toInt(), p.pos.y.toInt(), (p.pos.z + F(PLAYER_HW)).toInt(), BALL_E_PLAYER, p.vel));
    if (rolling) { b.vel.x = b.vel.x * BALL_ROLL; b.vel.z = b.vel.z * BALL_ROLL; }
    else         { b.vel.x = b.vel.x * BALL_DRAG; b.vel.z = b.vel.z * BALL_DRAG; }
    if (impact > SOUND_SPEED) sfx::bounce(i, impact.toInt());
    // Roll: angle = distance / radius (4096 / (2*pi*40) ~ 16 angle units per world unit).
    b.spinX = (b.spinX - (b.vel.z.raw >> 8)) & 4095;
    b.spinZ = (b.spinZ + (b.vel.x.raw >> 8)) & 4095;
}

void collideBalls() {
    constexpr int D = 2 * BALL_R, D16 = D * 16;
    for (int i = 0; i < MAX_BALLS; i++) {
        Ball& a = g.balls[i];
        if (!a.active) continue;
        for (int j = i + 1; j < MAX_BALLS; j++) {
            Ball& b = g.balls[j];
            if (!b.active) continue;
            const Vec3 d = b.pos - a.pos;
            if (util::abs(d.x) >= F(D) || util::abs(d.y) >= F(D) || util::abs(d.z) >= F(D)) continue;
            const int dx = d.x.raw >> 8, dy = d.y.raw >> 8, dz = d.z.raw >> 8;
            const int d2 = dx * dx + dy * dy + dz * dz;
            if (d2 >= D16 * D16) continue;
            const int dist = SquareRoot0(d2);
            const Vec3 n = dist ? normalOf(dx, dy, dz, dist) : Vec3{1_fx, 0_fx, 0_fx};
            const int pen = D16 - dist;                // separate both balls by half the overlap
            a.pos -= n * fx::fromRaw((pen / 2) << 8);
            b.pos += n * fx::fromRaw((pen - pen / 2) << 8);
            const fx vrel = (b.vel - a.vel).dot(n);
            if (vrel >= 0_fx) continue;
            const fx j2 = vrel * (1_fx + BALL_E_BALL) / 2;   // equal masses: half the impulse each
            a.vel += n * j2;
            b.vel -= n * j2;
            if (-vrel > SOUND_SPEED) sfx::bounce(i, (-vrel).toInt());
        }
    }
}

void kick() {
    const Player& p = g.player;
    const Vec3 f = facing(p.yaw);
    int hits = 0;
    for (int i = 0; i < MAX_BALLS; i++) {
        Ball& b = g.balls[i];
        if (!b.active) continue;
        const int dx = (b.pos.x - p.pos.x).toInt(), dz = (b.pos.z - p.pos.z).toInt();
        const int dy = (b.pos.y - p.pos.y).toInt();   // 0 at the feet, negative above
        if (dx * dx + dz * dz > KICK_RANGE * KICK_RANGE) continue;
        if (dx * isin(p.yaw) + dz * icos(p.yaw) < 0) continue;   // behind the player
        if (dy < -PLAYER_H - BALL_R || dy > BALL_R) continue;
        b.vel = f * 10_fx + Vec3{p.vel.x / 2, -8_fx, p.vel.z / 2};
        hits++;
    }
    sfx::kick(hits > 0);
    dbg::log("KICK frame=%d hits=%d\n", g.frame, hits);
}

void throwBall() {
    const Player& p = g.player;
    const int i = g.nextBall;
    g.nextBall = (g.nextBall + 1) % MAX_BALLS;
    const Vec3 f = facing(p.yaw);
    Ball& b = g.balls[i];
    b.pos = p.pos + f * F(PLAYER_HW + BALL_R + 6) + Vec3{0_fx, F(-90), 0_fx};
    b.vel = f * 8_fx + Vec3{p.vel.x, -6_fx, p.vel.z};
    b.active = true;
    sfx::throwBall();
    dbg::log("THROW frame=%d ball=%d\n", g.frame, i);
}
}  // namespace

const char* camModeName(CamMode m) {
    switch (m) {
    case CamMode::ORBIT:  return "ORBIT";
    case CamMode::FOLLOW: return "FOLLOW";
    case CamMode::TOP:    return "TOP";
    default:              return "?";
    }
}

void init() {
    using namespace assets;
    g.numBoxes = 0;
    auto add = [](const Box& b) { if (g.numBoxes < MAX_BOXES) g.boxes[g.numBoxes++] = b; };
    // Walls in segments: the ones along X also cover the corners.
    constexpr int OUT = ARENA + WALL_T, LX = 2 * OUT / WALL_SEGMENTS, LZ = 2 * ARENA / WALL_SEGMENTS;
    for (int s = 0; s < WALL_SEGMENTS; s++) {
        const int x = -OUT + s * LX, z = -ARENA + s * LZ;
        add({int16_t(x), int16_t(-OUT), int16_t(x + LX), int16_t(-ARENA), 0, WALL_H, C_WALL});
        add({int16_t(x), int16_t(ARENA), int16_t(x + LX), int16_t(OUT), 0, WALL_H, C_WALL});
        add({int16_t(-OUT), int16_t(z), int16_t(-ARENA), int16_t(z + LZ), 0, WALL_H, C_WALL});
        add({int16_t(ARENA), int16_t(z), int16_t(OUT), int16_t(z + LZ), 0, WALL_H, C_WALL});
    }
    g.firstObstacle = g.numBoxes;
    for (const Box& b : OBSTACLES) add(b);
    g.cam.mode = CamMode::ORBIT;
    reset();
}

void reset() {
    using namespace assets;
    g.player = Player{};
    g.player.pos = { F(PLAYER_START_X), 0_fx, F(PLAYER_START_Z) };
    g.player.onGround = true;
    for (Ball& b : g.balls) b = Ball{};
    int n = 0;
    for (const BallStart& s : BALL_STARTS) {
        Ball& b = g.balls[n++];
        b.pos = { F(s.x), F(-s.h), F(s.z) };
        b.vel = { F(s.vx), 0_fx, F(s.vz) };
        b.active = true;
    }
    g.nextBall = n;
    Camera& k = g.cam;
    k.yaw = k.yawGoal = 0;
    k.pitch = 300;
    k.dist = k.distGoal = 720;
    k.target = g.player.pos + Vec3{0_fx, F(-CHEST), 0_fx};
    dbg::log("RESET frame=%d balls=%d boxes=%d\n", g.frame, n, g.numBoxes);
}

void step(const Controls& c) {
    if (c.throwBall) throwBall();
    if (c.kick) kick();
    stepPlayer(c);
    for (int i = 0; i < MAX_BALLS; i++) if (g.balls[i].active) stepBall(i);
    collideBalls();
}

void updateCamera(const Controls& c) {
    Camera& k = g.cam;
    if (c.nextCamMode) {
        k.mode = CamMode((int(k.mode) + 1) % int(CamMode::COUNT));
        sfx::ui();
        dbg::log("CAM frame=%d mode=%s\n", g.frame, camModeName(k.mode));
    }
    k.yawGoal = (k.yawGoal + c.orbit * 40) & 4095;              // ~210 deg/s
    k.distGoal = util::clamp(k.distGoal + c.zoom * 14, CAM_DIST_MIN, CAM_DIST_MAX);
    const Player& p = g.player;
    if (k.mode == CamMode::FOLLOW && c.orbit == 0) {           // swing behind the player while running
        const int diff = util::angleDiff(k.yawGoal, p.yaw);
        const bool running = util::abs(p.vel.x) + util::abs(p.vel.z) > 1.5_fx;
        if (running && util::abs(diff) < 1400) k.yawGoal = (k.yawGoal + diff / 20) & 4095;
    }
    const int pitchGoal = k.mode == CamMode::TOP ? 820 : (k.mode == CamMode::FOLLOW ? 250 : 300);
    const int dy = util::angleDiff(k.yaw, k.yawGoal);
    k.yaw = (k.yaw + (util::abs(dy) < 4 ? dy : dy / 4)) & 4095;
    k.pitch += (pitchGoal - k.pitch) / 8;
    k.dist += (k.distGoal - k.dist) / 6;
    const Vec3 chest = p.pos + Vec3{0_fx, F(-CHEST), 0_fx};
    k.target += Vec3{(chest.x - k.target.x) / 4, (chest.y - k.target.y) / 4, (chest.z - k.target.z) / 4};

    const int sp = isin(k.pitch), cp = icos(k.pitch), sy = isin(k.yaw), cy = icos(k.yaw);
    const int tx = k.target.x.toInt(), ty = k.target.y.toInt(), tz = k.target.z.toInt();
    const int hd = (k.dist * cp) >> 12;                        // horizontal part of the distance
    k.at  = { tx, ty, tz };
    k.eye = { tx - ((hd * sy) >> 12), util::min(ty - ((k.dist * sp) >> 12), -30), tz - ((hd * cy) >> 12) };

    if (c.orbitReleased || c.zoomReleased)
        dbg::log("CAM frame=%d yaw=%d dist=%d\n", g.frame, k.yawGoal, k.distGoal);
}

int groundBelow(int x, int z, int height, int* boxIndex) {
    int best = 0;
    *boxIndex = -1;
    for (int i = g.firstObstacle; i < g.numBoxes; i++) {
        const Box& b = g.boxes[i];
        if (x < b.x0 || x > b.x1 || z < b.z0 || z > b.z1 || b.top > height + 2 || b.top <= best) continue;
        best = b.top;
        *boxIndex = i;
    }
    return best;
}

int restingBalls() {
    int n = 0;
    for (const Ball& b : g.balls)
        if (b.active && b.vel.y == 0_fx && util::abs(b.vel.x) < 0.2_fx && util::abs(b.vel.z) < 0.2_fx) n++;
    return n;
}
}  // namespace world
