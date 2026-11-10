#include "gte3d.hpp"
#include <cassert>
#include <inline_c.h>
#include "util.hpp"

// The SDK's GTE load macros (gte_ldv*, gte_ldrgb, gte_Set*Matrix) take pointers but do not
// tell the compiler they read memory: at -O2 stores to that memory can be delayed or even
// dropped (seen with a local MATRIX). Put a barrier before loading anything just written.
#define GTE_BARRIER() __asm__ volatile("" ::: "memory")

namespace gte3d {
namespace {
constexpr int HALF_W = gfx::SCREEN_W / 2, HALF_H = gfx::SCREEN_H / 2;
constexpr int isqrtc(int v) { int r = 0; while ((r + 1) * (r + 1) <= v) r++; return r; }
// Lengths of the side-plane normals (H, 0, -HALF_W) and (0, H, -HALF_H), for sphere culling.
constexpr int NORM_X = isqrtc(SCREEN_DIST * SCREEN_DIST + HALF_W * HALF_W) + 1;
constexpr int NORM_Y = isqrtc(SCREEN_DIST * SCREEN_DIST + HALF_H * HALF_H) + 1;

// Per-vertex outcodes, computed once per transformed vertex so faces are rejected with a
// few AND/OR operations: a face is dropped if any vertex has a DROP bit, and is off-screen
// if all its vertices share an edge bit.
enum : uint8_t {
    OC_LEFT = 1, OC_RIGHT = 2, OC_TOP = 4, OC_BOTTOM = 8,
    OC_NEAR = 16, OC_FAR = 32, OC_SAT = 64,   // closer than NEAR, beyond FAR, GTE saturated
    OC_CLOSE = 128,                           // close enough that the polygon may exceed the GPU limit
};
constexpr uint8_t OC_EDGES = 15, OC_DROP = OC_NEAR | OC_FAR | OC_SAT;
constexpr int CLOSE_Z = 192;
constexpr uint32_t CODE_F3 = 0x20u << 24, CODE_F4 = 0x28u << 24, CODE_G4 = 0x38u << 24;

MATRIX g_view;                      // world -> camera
MATRIX g_light;                     // row 0: direction toward the light (world space)
int    g_faces = 0;

struct Projected {                  // GTE stores (swc2) need 4-byte aligned targets
    alignas(4) DVECTOR sxy[MAX_MESH_VERTS];
    alignas(4) int32_t sz[MAX_MESH_VERTS];
    uint8_t oc[MAX_MESH_VERTS];
};
Projected g_mesh;

constexpr int FLOOR_MAX = 17 * 17;
alignas(4) SVECTOR  g_floorV[FLOOR_MAX];
alignas(4) DVECTOR  g_floorSxy[FLOOR_MAX];
alignas(4) int32_t  g_floorSz[FLOOR_MAX];
uint8_t  g_floorOc[FLOOR_MAX];
uint32_t g_floorCol[2][FLOOR_MAX];  // fogged checker colors per vertex, 0x00BBGGRR
int g_floorNx = 0, g_floorNz = 0;

// Box corner index = xbit | ybit << 1 | zbit << 2 (bit set = max side).
// Faces in Z order as seen from outside (v0 v1 top, v2 v3 bottom); normals point outwards.
constexpr Face BOX_FACES[6] = {
    {{0, 0, -ONE, 0}, {0, 1, 2, 3}, 1, 0},   // -Z (back of a model)
    {{0, 0, ONE, 0},  {5, 4, 7, 6}, 1, 1},   // +Z (front of a model: color 1 in addBox)
    {{0, -ONE, 0, 0}, {4, 5, 0, 1}, 1, 0},   // top (-Y)
    {{0, ONE, 0, 0},  {7, 6, 3, 2}, 1, 0},   // bottom (+Y)
    {{-ONE, 0, 0, 0}, {4, 0, 6, 2}, 1, 0},   // -X
    {{ONE, 0, 0, 0},  {1, 5, 3, 7}, 1, 0},   // +X
};

// x | y << 16 as one word, as primitives store it. v must be 4-byte aligned (one lw).
inline uint32_t word(const DVECTOR& v) { return *reinterpret_cast<const uint32_t*>(&v); }
inline uint32_t rgb(const CVECTOR& c) { return uint32_t(c.r) | (uint32_t(c.g) << 8) | (uint32_t(c.b) << 16); }

void transform(const SVECTOR* v, int n, DVECTOR* sxy, int32_t* sz, uint8_t* oc) {
    GTE_BARRIER();
    int i = 0;
    for (; i + 3 <= n; i += 3) {    // 3 vertices per GTE op
        gte_ldv3(&v[i], &v[i + 1], &v[i + 2]);
        gte_rtpt();
        gte_stsxy3(&sxy[i], &sxy[i + 1], &sxy[i + 2]);
        gte_stsz3(&sz[i], &sz[i + 1], &sz[i + 2]);
    }
    for (; i < n; i++) {
        gte_ldv0(&v[i]);
        gte_rtps();
        gte_stsxy(&sxy[i]);
        gte_stsz(&sz[i]);
    }
    for (i = 0; i < n; i++) {
        const int x = sxy[i].vx, y = sxy[i].vy, z = sz[i];
        uint8_t o = 0;
        if (x < 0) o |= OC_LEFT; else if (x >= gfx::SCREEN_W) o |= OC_RIGHT;
        if (y < 0) o |= OC_TOP;  else if (y >= gfx::SCREEN_H) o |= OC_BOTTOM;
        if (z < CLOSE_Z) o |= (z < NEAR) ? (OC_NEAR | OC_CLOSE) : OC_CLOSE;
        else if (z > FAR) o |= OC_FAR;
        if (uint32_t(x + 1023) > 2045u || uint32_t(y + 1023) > 2045u) o |= OC_SAT;   // |x| or |y| >= 1023
        oc[i] = o;
    }
}

// True when a sphere (camera-space centre c, radius r) is completely outside the view.
bool culled(const VECTOR& c, int r) {
    if (c.vz + r < NEAR || c.vz - r > FAR) return true;
    const int hz = HALF_W * c.vz, vz = HALF_H * c.vz;
    if ( SCREEN_DIST * c.vx - hz > r * NORM_X) return true;
    if (-SCREEN_DIST * c.vx - hz > r * NORM_X) return true;
    if ( SCREEN_DIST * c.vy - vz > r * NORM_Y) return true;
    if (-SCREEN_DIST * c.vy - vz > r * NORM_Y) return true;
    return false;
}

// Only for faces with a vertex closer than CLOSE_Z: the GPU drops polygons over 1023x511.
bool tooBig(const DVECTOR* p, int n) {
    int xmin = p[0].vx, xmax = xmin, ymin = p[0].vy, ymax = ymin;
    for (int k = 1; k < n; k++) {
        xmin = util::min<int>(xmin, p[k].vx); xmax = util::max<int>(xmax, p[k].vx);
        ymin = util::min<int>(ymin, p[k].vy); ymax = util::max<int>(ymax, p[k].vy);
    }
    return xmax - xmin > 1023 || ymax - ymin > 511;
}

// Light a flat color with normal n (object space) and store it, with the primitive code, at out.
inline void light(uint32_t* out, uint32_t rgbc, const SVECTOR* n) {
    __asm__ volatile("mtc2 %0, $6" : : "r"(rgbc));   // RGBC (gte_nccs has the 2 nops it needs)
    gte_ldv0(n);
    gte_nccs();                                      // color * (ambient + light * max(0, n.l))
    gte_strgb(out);
}

void drawFace(const Face& f, const Projected& pr, uint32_t color) {
    const int a = f.v[0], b = f.v[1], c = f.v[2], d = f.v[3];   // triangles repeat a vertex in v[3]
    const uint8_t oa = pr.oc[a], ob = pr.oc[b], occ = pr.oc[c], od = pr.oc[d];
    const uint8_t any = oa | ob | occ | od;
    if ((any & OC_DROP) || (oa & ob & occ & od & OC_EDGES)) return;
    alignas(4) const DVECTOR p[4] = { pr.sxy[a], pr.sxy[b], pr.sxy[c], pr.sxy[d] };   // word() needs alignment
    // Back-face test on the first triangle (same formula as gte_nclip).
    if ((p[1].vx - p[0].vx) * (p[2].vy - p[0].vy) - (p[2].vx - p[0].vx) * (p[1].vy - p[0].vy) <= 0) return;
    if ((any & OC_CLOSE) && tooBig(p, f.quad ? 4 : 3)) return;
    if (f.quad) {
        const int z = (pr.sz[a] + pr.sz[b] + pr.sz[c] + pr.sz[d]) >> (2 + DEPTH_SHIFT);
        POLY_F4* q = gfx::next<POLY_F4>();
        setlen(q, 5);
        light(reinterpret_cast<uint32_t*>(&q->r0), color | CODE_F4, &f.n);
        *reinterpret_cast<uint32_t*>(&q->x0) = word(p[0]);
        *reinterpret_cast<uint32_t*>(&q->x1) = word(p[1]);
        *reinterpret_cast<uint32_t*>(&q->x2) = word(p[2]);
        *reinterpret_cast<uint32_t*>(&q->x3) = word(p[3]);
        gfx::commit(q, gfx::slot3D(util::min(z, OBJ_SLOTS - 1)));
    } else {
        const int z = ((pr.sz[a] + pr.sz[b] + pr.sz[c]) * 21) >> (6 + DEPTH_SHIFT);   // * 21/64 ~ / 3
        POLY_F3* t = gfx::next<POLY_F3>();
        setlen(t, 4);
        light(reinterpret_cast<uint32_t*>(&t->r0), color | CODE_F3, &f.n);
        *reinterpret_cast<uint32_t*>(&t->x0) = word(p[0]);
        *reinterpret_cast<uint32_t*>(&t->x1) = word(p[1]);
        *reinterpret_cast<uint32_t*>(&t->x2) = word(p[2]);
        gfx::commit(t, gfx::slot3D(util::min(z, OBJ_SLOTS - 1)));
    }
    g_faces++;
}

void growRadius(Mesh& m, const SVECTOR& v) {
    const int r = SquareRoot0(v.vx * v.vx + v.vy * v.vy + v.vz * v.vz) + 1;
    if (r > m.radius) m.radius = r;
}

// Make the face point away from (cx, cy, cz): a visible face's edge cross product
// (v1-v0) x (v2-v0) points INTO the object (screen y grows downwards).
void fixWinding(const Mesh& m, Face& f, int cx, int cy, int cz) {
    const SVECTOR &a = m.verts[f.v[0]], &b = m.verts[f.v[1]], &c = m.verts[f.v[2]];
    const int e1x = b.vx - a.vx, e1y = b.vy - a.vy, e1z = b.vz - a.vz;
    const int e2x = c.vx - a.vx, e2y = c.vy - a.vy, e2z = c.vz - a.vz;
    const int crx = e1y * e2z - e1z * e2y, cry = e1z * e2x - e1x * e2z, crz = e1x * e2y - e1y * e2x;
    const int ox = a.vx + b.vx + c.vx - 3 * cx, oy = a.vy + b.vy + c.vy - 3 * cy, oz = a.vz + b.vz + c.vz - 3 * cz;
    if (crx * ox + cry * oy + crz * oz > 0) util::swap(f.v[1], f.v[2]);   // keeps Z order for quads
}
}  // namespace

void addBox(Mesh& m, int x0, int y0, int z0, int x1, int y1, int z1, uint8_t color, uint8_t front) {
    if (x0 > x1) util::swap(x0, x1);
    if (y0 > y1) util::swap(y0, y1);
    if (z0 > z1) util::swap(z0, z1);
    assert(m.numVerts + 8 <= m.maxVerts && m.numFaces + 6 <= m.maxFaces && m.numVerts + 8 <= MAX_MESH_VERTS);
    const int base = m.numVerts;
    for (int i = 0; i < 8; i++) {
        SVECTOR& v = m.verts[base + i];
        v = { int16_t(i & 1 ? x1 : x0), int16_t(i & 2 ? y1 : y0), int16_t(i & 4 ? z1 : z0), 0 };
        growRadius(m, v);
    }
    for (const Face& bf : BOX_FACES) {
        Face& f = m.faces[m.numFaces++];
        f = bf;
        for (int k = 0; k < 4; k++) f.v[k] = uint8_t(base + bf.v[k]);
        f.color = bf.color ? front : color;
    }
    m.numVerts += 8;
}

void addSphere(Mesh& m, int r, int seg, int rings) {
    const int nv = 2 + seg * (rings - 1);
    assert(m.numVerts + nv <= m.maxVerts && m.numFaces + seg * rings <= m.maxFaces && m.numVerts + nv <= MAX_MESH_VERTS);
    const int top = m.numVerts, bottom = top + nv - 1;
    auto ringV = [&](int ring, int s) { return top + 1 + (ring - 1) * seg + (s % seg); };
    m.verts[top]    = { 0, int16_t(-r), 0, 0 };
    m.verts[bottom] = { 0, int16_t(r), 0, 0 };
    for (int ring = 1; ring < rings; ring++) {
        const int phi = ring * 2048 / rings;                  // 0..180 deg from the top
        const int y = -(r * icos(phi)) >> 12, rr = (r * isin(phi)) >> 12;
        for (int s = 0; s < seg; s++) {
            const int th = s * 4096 / seg;
            m.verts[ringV(ring, s)] = { int16_t((rr * icos(th)) >> 12), int16_t(y), int16_t((rr * isin(th)) >> 12), 0 };
        }
    }
    for (int i = top; i <= bottom; i++) growRadius(m, m.verts[i]);
    m.numVerts += nv;
    for (int ring = 0; ring < rings; ring++) {
        for (int s = 0; s < seg; s++) {
            Face& f = m.faces[m.numFaces++];
            f.color = uint8_t(s & 1);
            if (ring == 0) {
                f.quad = 0; f.v[0] = uint8_t(top); f.v[1] = uint8_t(ringV(1, s)); f.v[2] = uint8_t(ringV(1, s + 1));
            } else if (ring == rings - 1) {
                f.quad = 0; f.v[0] = uint8_t(ringV(ring, s)); f.v[1] = uint8_t(ringV(ring, s + 1)); f.v[2] = uint8_t(bottom);
            } else {
                f.quad = 1;
                f.v[0] = uint8_t(ringV(ring, s));     f.v[1] = uint8_t(ringV(ring, s + 1));
                f.v[2] = uint8_t(ringV(ring + 1, s)); f.v[3] = uint8_t(ringV(ring + 1, s + 1));
            }
            fixWinding(m, f, 0, 0, 0);
            if (!f.quad) f.v[3] = f.v[2];                     // triangles repeat a vertex
            const int n = f.quad ? 4 : 3;                     // normal = direction of the centroid
            VECTOR c = { 0, 0, 0 };
            for (int k = 0; k < n; k++) { c.vx += m.verts[f.v[k]].vx; c.vy += m.verts[f.v[k]].vy; c.vz += m.verts[f.v[k]].vz; }
            VectorNormalS(&c, &f.n);
        }
    }
}

void init() {
    InitGeom();
    gte_SetGeomOffset(HALF_W, HALF_H);
    gte_SetGeomScreen(SCREEN_DIST);
    setLight(-1638, -3277, -1843, 200, 200, 190, 104, 104, 112);   // from up-left-behind the default camera
}

void setLight(int dx, int dy, int dz, uint8_t r, uint8_t g, uint8_t b, uint8_t ar, uint8_t ag, uint8_t ab) {
    g_light = {};
    g_light.m[0][0] = int16_t(dx); g_light.m[0][1] = int16_t(dy); g_light.m[0][2] = int16_t(dz);
    MATRIX col = {};
    col.m[0][0] = int16_t(r * 16); col.m[1][0] = int16_t(g * 16); col.m[2][0] = int16_t(b * 16);
    GTE_BARRIER();             // without it -O2 drops the stores to `col` (the asm hides the read)
    gte_SetColorMatrix(&col);
    gte_SetBackColor(ar, ag, ab);
}

void lookAt(const VECTOR& eye, const VECTOR& at) {
    auto cross = [](const SVECTOR& a, const SVECTOR& b) {
        return VECTOR{ (a.vy * b.vz - a.vz * b.vy) >> 12, (a.vz * b.vx - a.vx * b.vz) >> 12,
                       (a.vx * b.vy - a.vy * b.vx) >> 12 };
    };
    VECTOR t = { at.vx - eye.vx, at.vy - eye.vy, at.vz - eye.vz };
    SVECTOR zAxis, xAxis, yAxis;
    const SVECTOR up = { 0, -ONE, 0, 0 };
    VectorNormalS(&t, &zAxis);
    t = cross(zAxis, up);    VectorNormalS(&t, &xAxis);
    t = cross(zAxis, xAxis); VectorNormalS(&t, &yAxis);
    g_view.m[0][0] = xAxis.vx; g_view.m[0][1] = xAxis.vy; g_view.m[0][2] = xAxis.vz;
    g_view.m[1][0] = yAxis.vx; g_view.m[1][1] = yAxis.vy; g_view.m[1][2] = yAxis.vz;
    g_view.m[2][0] = zAxis.vx; g_view.m[2][1] = zAxis.vy; g_view.m[2][2] = zAxis.vz;
    VECTOR negEye = { -eye.vx, -eye.vy, -eye.vz }, tr;
    ApplyMatrixLV(&g_view, &negEye, &tr);
    TransMatrix(&g_view, &tr);
    g_faces = 0;
}

VECTOR toCamera(int x, int y, int z) {
    const MATRIX& m = g_view;
    return VECTOR{ ((m.m[0][0] * x + m.m[0][1] * y + m.m[0][2] * z) >> 12) + m.t[0],
                   ((m.m[1][0] * x + m.m[1][1] * y + m.m[1][2] * z) >> 12) + m.t[1],
                   ((m.m[2][0] * x + m.m[2][1] * y + m.m[2][2] * z) >> 12) + m.t[2] };
}

int slotAt(int x, int y, int z) {
    return util::clamp<int>(toCamera(x, y, z).vz >> DEPTH_SHIFT, 0, OBJ_SLOTS - 1);
}

int facesDrawn() { return g_faces; }

void drawMesh(const Mesh& m, const VECTOR& pos, const SVECTOR& rot, const CVECTOR* palette) {
    if (culled(toCamera(pos.vx, pos.vy, pos.vz), m.radius)) return;
    MATRIX om, mv, lm;
    SVECTOR r = rot;      // the SDK takes non-const pointers
    VECTOR  p = pos;
    RotMatrix(&r, &om);
    TransMatrix(&om, &p);
    MulMatrix0(&g_light, &om, &lm);   // light directions into object space
    CompMatrixLV(&g_view, &om, &mv);  // object -> camera
    GTE_BARRIER();
    gte_SetRotMatrix(&mv);
    gte_SetTransMatrix(&mv);
    gte_SetLightMatrix(&lm);
    transform(m.verts, m.numVerts, g_mesh.sxy, g_mesh.sz, g_mesh.oc);
    for (int i = 0; i < m.numFaces; i++) drawFace(m.faces[i], g_mesh, rgb(palette[m.faces[i].color]));
}

void drawBox(int x0, int y0, int z0, int x1, int y1, int z1, CVECTOR color) {
    if (x0 > x1) util::swap(x0, x1);
    if (y0 > y1) util::swap(y0, y1);
    if (z0 > z1) util::swap(z0, z1);
    const int radius = (x1 - x0) / 2 + (y1 - y0) / 2 + (z1 - z0) / 2;   // >= half diagonal
    if (culled(toCamera((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), radius)) return;
    alignas(4) SVECTOR v[8];
    for (int i = 0; i < 8; i++)
        v[i] = { int16_t(i & 1 ? x1 : x0), int16_t(i & 2 ? y1 : y0), int16_t(i & 4 ? z1 : z0), 0 };
    gte_SetRotMatrix(&g_view);
    gte_SetTransMatrix(&g_view);
    gte_SetLightMatrix(&g_light);
    transform(v, 8, g_mesh.sxy, g_mesh.sz, g_mesh.oc);
    const uint32_t c = rgb(color);
    for (const Face& f : BOX_FACES) drawFace(f, g_mesh, c);
}

void setFloor(int x0, int z0, int tile, int nx, int nz) {
    assert(nx >= 1 && nz >= 1 && nx <= 16 && nz <= 16);
    g_floorNx = nx; g_floorNz = nz;
    for (int j = 0; j <= nz; j++)
        for (int i = 0; i <= nx; i++)
            g_floorV[j * (nx + 1) + i] = { int16_t(x0 + i * tile), 0, int16_t(z0 + j * tile), 0 };
}

void drawFloor(CVECTOR a, CVECTOR b, CVECTOR fog, int fogStart) {
    const int w = g_floorNx + 1, n = w * (g_floorNz + 1);
    gte_SetRotMatrix(&g_view);
    gte_SetTransMatrix(&g_view);
    transform(g_floorV, n, g_floorSxy, g_floorSz, g_floorOc);
    // Both checker colors per vertex, mixed toward `fog` (0..128) between fogStart and FAR.
    const int recip = (128 << 16) / (FAR - fogStart);
    const uint32_t ca = rgb(a), cb = rgb(b);
    for (int i = 0; i < n; i++) {
        const int f = util::min<int>(((g_floorSz[i] - fogStart) * recip) >> 16, 128);
        if (f <= 0) { g_floorCol[0][i] = ca; g_floorCol[1][i] = cb; continue; }
        auto mix = [f](int c0, int c1) { return uint32_t(c0 + (((c1 - c0) * f) >> 7)); };
        g_floorCol[0][i] = mix(a.r, fog.r) | (mix(a.g, fog.g) << 8) | (mix(a.b, fog.b) << 16);
        g_floorCol[1][i] = mix(b.r, fog.r) | (mix(b.g, fog.g) << 8) | (mix(b.b, fog.b) << 16);
    }
    const int slot = gfx::slot3D(FLOOR_SLOT);
    for (int j = 0; j < g_floorNz; j++) {
        for (int i = 0; i < g_floorNx; i++) {
            const int i0 = j * w + i, i1 = i0 + 1, i2 = i0 + w, i3 = i2 + 1;
            const uint8_t o0 = g_floorOc[i0], o1 = g_floorOc[i1], o2 = g_floorOc[i2], o3 = g_floorOc[i3];
            const uint8_t any = o0 | o1 | o2 | o3;
            if ((any & OC_DROP) || (o0 & o1 & o2 & o3 & OC_EDGES)) continue;
            if (any & OC_CLOSE) {
                const DVECTOR p[4] = { g_floorSxy[i0], g_floorSxy[i1], g_floorSxy[i2], g_floorSxy[i3] };
                if (tooBig(p, 4)) continue;
            }
            const uint32_t* col = g_floorCol[(i + j) & 1];
            POLY_G4* q = gfx::next<POLY_G4>();
            setlen(q, 8);
            uint32_t* w32 = reinterpret_cast<uint32_t*>(q);      // tag, rgb0|code, xy0, rgb1, xy1, ...
            w32[1] = col[i0] | CODE_G4; w32[2] = word(g_floorSxy[i0]);
            w32[3] = col[i1];           w32[4] = word(g_floorSxy[i1]);
            w32[5] = col[i2];           w32[6] = word(g_floorSxy[i2]);
            w32[7] = col[i3];           w32[8] = word(g_floorSxy[i3]);
            gfx::commit(q, slot);
            g_faces++;
        }
    }
}

void drawShadow(int x, int y, int z, int radius, int slot) {
    if (culled(toCamera(x, y, z), radius)) return;
    alignas(4) SVECTOR v[9];
    v[0] = { int16_t(x), int16_t(y), int16_t(z), 0 };
    for (int k = 0; k < 8; k++)
        v[1 + k] = { int16_t(x + ((radius * icos(k * 512)) >> 12)), int16_t(y),
                     int16_t(z + ((radius * isin(k * 512)) >> 12)), 0 };
    gte_SetRotMatrix(&g_view);
    gte_SetTransMatrix(&g_view);
    transform(v, 9, g_mesh.sxy, g_mesh.sz, g_mesh.oc);
    const uint8_t* oc = g_mesh.oc;
    const int s = gfx::slot3D(slot);
    bool any = false;
    for (int k = 0; k < 8; k++) {             // fan of 8 triangles around the centre
        const int i1 = 1 + k, i2 = 1 + ((k + 1) & 7);
        if (((oc[0] | oc[i1] | oc[i2]) & OC_DROP) || (oc[0] & oc[i1] & oc[i2] & OC_EDGES)) continue;
        POLY_F3* t = gfx::next<POLY_F3>();
        setPolyF3(t);
        setSemiTrans(t, 1);
        setRGB0(t, 0, 0, 0);                   // 50/50 blend with black = half brightness
        *reinterpret_cast<uint32_t*>(&t->x0) = word(g_mesh.sxy[0]);
        *reinterpret_cast<uint32_t*>(&t->x1) = word(g_mesh.sxy[i1]);
        *reinterpret_cast<uint32_t*>(&t->x2) = word(g_mesh.sxy[i2]);
        gfx::commit(t, s);
        any = true;
    }
    if (any) {                                 // committed last = executed first in this slot
        DR_TPAGE* tp = gfx::next<DR_TPAGE>();
        setDrawTPage(tp, 1, 1, getTPage(0, 0, 0, 0));   // blend mode abr 0 = 50/50
        gfx::commit(tp, s);
    }
}
}  // namespace gte3d
