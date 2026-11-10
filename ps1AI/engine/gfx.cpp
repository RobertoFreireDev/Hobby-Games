#include "gfx.hpp"
#include <cassert>
#include <cstring>

namespace gfx {
namespace detail {
uint8_t*  next = nullptr;
uint8_t*  end  = nullptr;
uint32_t* ot   = nullptr;
}
namespace {
struct Buffer {
    DISPENV  disp;
    DRAWENV  draw;
    uint32_t ot[OT_LEN];
    uint8_t  prims[BUF_LEN];
};
Buffer   g_buf[2];
int      g_cur = 0;
// 4bpp sprite allocator: pages x = 320..896 step 64, y = 0 / 256. CLUTs at y = 480..511.
int g_pageX = 320, g_pageY = 0, g_penU = 0, g_penV = 0, g_rowH = 0;
int g_clutX = 0, g_clutY = 480;

template <typename T> T* alloc(int z) {   // 2D layer z = 0..15
    T* p = next<T>();
    commit(p, slot2D(z));
    return p;
}
void beginFrame(int buf) {   // make buffer `buf` the one primitives go into
    g_cur = buf;
    detail::next = g_buf[buf].prims;
    detail::end  = g_buf[buf].prims + BUF_LEN;
    detail::ot   = g_buf[buf].ot;
    ClearOTagR(g_buf[buf].ot, OT_LEN);
}
int hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return 0;
}
}  // namespace

void init(uint8_t r, uint8_t g, uint8_t b) {
    ResetGraph(0);
    SetVideoMode(MODE_NTSC);
    for (int i = 0; i < 2; i++) {   // draw into one buffer while showing the other
        SetDefDispEnv(&g_buf[i].disp, 0, i ? 0 : SCREEN_H, SCREEN_W, SCREEN_H);
        SetDefDrawEnv(&g_buf[i].draw, 0, i ? SCREEN_H : 0, SCREEN_W, SCREEN_H);
        setRGB0(&g_buf[i].draw, r, g, b);
        g_buf[i].draw.isbg = 1;
        g_buf[i].draw.dtd  = 1;     // dither gouraud/lit polygons (raw-textured sprites are unaffected)
    }
    FntLoad(960, 0);
    beginFrame(0);
    SetDispMask(1);
}

void flip() {
    DrawSync(0);
    VSync(0);
    PutDispEnv(&g_buf[g_cur].disp);
    DrawOTagEnv(&g_buf[g_cur].ot[OT_LEN - 1], &g_buf[g_cur].draw);
    beginFrame(g_cur ^ 1);
}

int primBytes() { return int(detail::next - g_buf[g_cur].prims); }

Texture uploadSprite(const char* const* rows, int w, int h, const uint16_t* palette) {
    assert((w % 8) == 0 && w <= 248 && h <= 248);
    static uint32_t pix[(256 * 256) / 8];
    static uint32_t clut[8];
    // Shelf packing; keep u+w and v+h <= 255 so POLY_FT4 UVs never wrap to 0.
    if (g_penU + w > 255) { g_penU = 0; g_penV += g_rowH; g_rowH = 0; }
    if (g_penV + h > 255) {
        g_penU = g_penV = g_rowH = 0;
        g_pageX += 64;
        if (g_pageX >= 960) { g_pageX = 320; g_pageY += 256; }
        assert(g_pageY < 512);
    }
    const int wpr = w / 8;                       // 8 pixels per uint32_t
    std::memset(pix, 0, size_t(wpr) * h * 4);
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
            pix[y * wpr + (x >> 3)] |= uint32_t(hexval(rows[y][x]) & 15) << ((x & 7) * 4);
    uint16_t* c16 = reinterpret_cast<uint16_t*>(clut);
    for (int i = 0; i < 16; i++) c16[i] = (i == 0) ? 0x0000 : palette[i];

    RECT img   = { int16_t(g_pageX + g_penU / 4), int16_t(g_pageY + g_penV), int16_t(w / 4), int16_t(h) };
    RECT crect = { int16_t(g_clutX), int16_t(g_clutY), 16, 1 };
    LoadImage(&img, pix);    DrawSync(0);
    LoadImage(&crect, clut); DrawSync(0);

    Texture t;
    t.tpage = getTPage(0, 0, g_pageX, g_pageY);  // 0 = 4bpp
    t.clut  = getClut(g_clutX, g_clutY);
    t.u = uint8_t(g_penU); t.v = uint8_t(g_penV); t.w = uint8_t(w); t.h = uint8_t(h);
    g_penU += w;
    if (h > g_rowH) g_rowH = h;
    g_clutX += 16;
    if (g_clutX >= 320) { g_clutX = 0; g_clutY++; assert(g_clutY < 512); }
    return t;
}

void sprite(const Texture& t, int x, int y, int z) {
    SPRT* s = alloc<SPRT>(z);
    setSprt(s);
    setShadeTex(s, 1);                 // raw texel colors
    setXY0(s, x, y);
    setWH(s, t.w, t.h);
    setUV0(s, t.u, t.v);
    s->clut = t.clut;
    DR_TPAGE* tp = alloc<DR_TPAGE>(z);  // added last = executed first (addPrim prepends)
    setDrawTPage(tp, 0, 0, t.tpage);
}

void rect(int x, int y, int w, int h, uint8_t r, uint8_t g, uint8_t b, int z) {
    TILE* t = alloc<TILE>(z);
    setTile(t);
    setXY0(t, x, y);
    setWH(t, w, h);
    setRGB0(t, r, g, b);
}

void vgradient(int x, int y, int w, int h, uint8_t r0, uint8_t g0, uint8_t b0,
               uint8_t r1, uint8_t g1, uint8_t b1, int z) {
    POLY_G4* p = alloc<POLY_G4>(z);
    setPolyG4(p);
    setXY4(p, x, y, x + w, y, x, y + h, x + w, y + h);
    setRGB0(p, r0, g0, b0); setRGB1(p, r0, g0, b0);
    setRGB2(p, r1, g1, b1); setRGB3(p, r1, g1, b1);
}

void text(int x, int y, const char* s, int z) {
    detail::next = reinterpret_cast<uint8_t*>(FntSort(&detail::ot[slot2D(z)], detail::next, x, y, s));
    assert(detail::next <= detail::end);
}
}  // namespace gfx
