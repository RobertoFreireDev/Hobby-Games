#pragma once
#include <cassert>
#include <cstdint>
#include <cstddef>
#include <psxgpu.h>

namespace gfx {
constexpr int SCREEN_W = 320;
constexpr int SCREEN_H = 240;

// Ordering table (lower slot = drawn later = in front):
//   slots 0..7                      2D layers z = 0..7  (HUD, sprites)  -> in front of 3D
//   slots 8 .. 8+OT_3D-1            3D depth band (gte3d), slot3D(0) is nearest
//   slots OT_3D+8 .. OT_3D+15       2D layers z = 8..15 (world, far background) -> behind 3D
// 2D-only games see the same 16 layers as before; the 3D band just sits between z=7 and z=8.
constexpr int OT_3D    = 1024;
constexpr int OT_LEN   = 16 + OT_3D;
constexpr int BUF_LEN  = 49152;   // primitive bytes per buffer; raise if asserts fire
constexpr int slot2D(int z)     { return z < 8 ? z : z + OT_3D; }
constexpr int slot3D(int depth) { return 8 + depth; }   // depth 0..OT_3D-1

// 15-bit color. CLUT index 0 is always transparent. Opaque black: rgb15(0,0,0) | 0x8000.
constexpr uint16_t rgb15(int r, int g, int b) {
    return uint16_t((r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10));
}

struct Texture {          // a sprite inside VRAM
    uint16_t tpage, clut;
    uint8_t  u, v, w, h;
};

void init(uint8_t bgR, uint8_t bgG, uint8_t bgB);
void flip();              // DrawSync + VSync + swap buffers + clear OT
int  primBytes();         // primitive bytes queued so far this frame (profiling)

// ASCII-art sprite -> 4bpp texture + CLUT. rows: h strings of w chars.
// '.' or '0' = transparent, '1'-'9' and 'A'-'F' = palette index. w multiple of 8, <= 248.
Texture uploadSprite(const char* const* rows, int w, int h, const uint16_t* palette16);

void sprite(const Texture& t, int x, int y, int z = 4);   // pixel-exact SPRT
void rect(int x, int y, int w, int h, uint8_t r, uint8_t g, uint8_t b, int z = 8);
void vgradient(int x, int y, int w, int h, uint8_t r0, uint8_t g0, uint8_t b0,
               uint8_t r1, uint8_t g1, uint8_t b1, int z = 15);   // top color -> bottom color
void text(int x, int y, const char* s, int z = 0);        // SDK debug font

// Raw primitive API (for engine modules such as gte3d): fill next<T>() in place, then
// commit it to an OT slot; a primitive that is never committed costs nothing. Inline: it runs
// for every polygon.
namespace detail {           // the frame being built; owned by gfx.cpp
extern uint8_t*  next;
extern uint8_t*  end;
extern uint32_t* ot;
}
inline void* primSpace() {   // free space for one primitive (<= 64 bytes)
    assert(detail::next + 64 <= detail::end);
    return detail::next;
}
inline void commit(void* p, size_t bytes, int slot) {
    assert(p == detail::next && slot >= 0 && slot < OT_LEN);
    detail::next += bytes;
    assert(detail::next <= detail::end);
    addPrim(&detail::ot[slot], p);
}
template <typename T> T* next() { return static_cast<T*>(primSpace()); }
template <typename T> void commit(T* p, int slot) { commit(p, sizeof(T), slot); }
}  // namespace gfx
