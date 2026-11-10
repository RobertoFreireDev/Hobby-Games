#pragma once
// Minimal GTE 3D renderer on top of gfx (flat-lit polygons, depth sorted in gfx's 3D band).
//
// World axes follow the GTE: X right, Y DOWN (the floor is y = 0, things above it have
// y < 0), Z forward. Angles: 4096 = 360 deg. All coordinates are integer world units.
//
// 3D band of the ordering table (gfx::slot3D):
//   0 .. OBJ_SLOTS-1   depth-sorted objects (camera z >> DEPTH_SHIFT)
//   SHADOW_SLOT        shadows on the floor
//   FLOOR_SLOT         the floor (drawn first: correct while the camera stays above it)
#include <cstdint>
#include <psxgte.h>
#include "gfx.hpp"

namespace gte3d {
constexpr int SCREEN_DIST = 200;   // projection plane distance H: horizontal FOV = 2*atan(160/H) = 77 deg
constexpr int NEAR = 40;           // faces with a vertex closer than this are dropped (PS1 has no clipping)
constexpr int FAR = 4000;          // faces with a vertex farther than this are dropped
constexpr int DEPTH_SHIFT = 2;     // camera z units per OT slot
constexpr int OBJ_SLOTS   = gfx::OT_3D - 2;
constexpr int SHADOW_SLOT = gfx::OT_3D - 2;
constexpr int FLOOR_SLOT  = gfx::OT_3D - 1;
constexpr int MAX_MESH_VERTS = 64;

struct alignas(4) Face {   // aligned: the GTE loads n with lwc2 (4-byte aligned word loads)
    SVECTOR n;         // outward unit normal (ONE = 4096), object space
    uint8_t v[4];      // quad in Z order (v0 v1 on top, v2 v3 below), triangle uses v0..v2
    uint8_t quad;      // 1 = quad, 0 = triangle
    uint8_t color;     // index into the palette given to drawMesh
};
struct Mesh {          // storage is owned by the caller: static, alignas(4) arrays
    SVECTOR* verts;
    Face*    faces;
    int maxVerts, maxFaces;
    int numVerts = 0, numFaces = 0;
    int radius = 0;    // bounding sphere around the object origin, for culling
};

// Builders (call at load time). Windings are fixed automatically so faces point outwards.
// Box from (x0,y0,z0) to (x1,y1,z1); the +Z face (the model's "front") gets frontColor.
void addBox(Mesh& m, int x0, int y0, int z0, int x1, int y1, int z1, uint8_t color, uint8_t frontColor);
// UV sphere centred on the origin: 2 + seg*(rings-1) verts, seg*rings faces, colors 0/1 striped by segment.
void addSphere(Mesh& m, int radius, int seg, int rings);

void init();           // after gfx::init()
// Directional light: (dx,dy,dz) points TOWARD the light (length ONE). Colors 0..255.
void setLight(int dx, int dy, int dz, uint8_t r, uint8_t g, uint8_t b, uint8_t ambR, uint8_t ambG, uint8_t ambB);
void lookAt(const VECTOR& eye, const VECTOR& target);   // once per frame, before drawing
VECTOR toCamera(int x, int y, int z);                   // world point -> camera space
int  slotAt(int x, int y, int z);                        // OT depth slot of a world point
int  facesDrawn();                                       // polygons queued since lookAt()

void drawMesh(const Mesh& m, const VECTOR& pos, const SVECTOR& rot, const CVECTOR* palette);
void drawBox(int x0, int y0, int z0, int x1, int y1, int z1, CVECTOR color);   // static world AABB

// Checkerboard floor at y = 0: nx*nz tiles of `tile` units starting at (x0, z0); nx, nz <= 16.
void setFloor(int x0, int z0, int tile, int nx, int nz);
void drawFloor(CVECTOR a, CVECTOR b, CVECTOR fog, int fogStart);
// Dark half-transparent disc on a horizontal surface at height y (y <= 0).
void drawShadow(int x, int y, int z, int radius, int slot = SHADOW_SLOT);
}  // namespace gte3d
