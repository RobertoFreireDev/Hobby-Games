#pragma bank 255
#include "engine/engine.h"
#include <string.h>
#include <stddef.h>
#include "assets.h"
#include "overworld.h"
#include "romcopy.h"

/* Big buffers at fixed addresses in WRAM bank 1 (D000-D6DF), outside the linker's RAM areas: game globals must
   stay below 0xD000 (the memory test writes D000-DBFF, GAME.md). Only this scene uses them and ow_init rebuilds
   them all, so the memory test overwriting them is harmless. */
#define SLOT_MEM ((uint8_t *)0xD000)                 /* 9 slots x 128 bytes: a wscreen_t each, map chars -> ids */
#define SLOT(s)  (SLOT_MEM + ((uint16_t)(s) << 7))
#define NAME_OFS offsetof(wscreen_t, name)
#define SIGN_OFS offsetof(wscreen_t, sign)
__at(0xD480) uint8_t ow_mt_tile[128];                 /* (metatile id << 2 | quadrant) -> VRAM tile */
__at(0xD500) uint8_t ow_mt_attr[128];                 /* same index -> BG attribute */
__at(0xD580) uint8_t ow_mt_lut[128];                  /* map char -> metatile id (unknown: 0, water) */
__at(0xD600) uint8_t ow_row_buf[64];                  /* pending row, laid out like a BG map row (GDMA source,
                                                         32-byte aligned): cell x at x & 31, attributes at +32 */
__at(0xD640) uint8_t ow_col_t[19];                    /* pending column: tiles */
__at(0xD660) uint8_t ow_col_a[19];                    /* pending column: attributes */
__at(0xD680) uint8_t ow_line[21];                     /* line being gathered: id << 2 | quadrant per cell */
__at(0xD6A0) uint8_t ow_mt_coll[32];                  /* metatile id -> COLL_* */
__at(0xD6C0) uint8_t ow_mt_tag[32];                   /* metatile id -> TAG_* */

/* one bank per world row: the bank numbers come from the linker, so they are read from &__bank_ symbols */
#define ROW_PTR_(n)  world_r##n,
#define ROW_BANK_(n) &__bank_world_r##n,
static const wscreen_t * const row_ptr[WORLD_H] = { WORLD_ROWS(ROW_PTR_) };
static const void * const row_bank[WORLD_H] = { WORLD_ROWS(ROW_BANK_) };

int16_t ow_cam_x, ow_cam_y;
uint16_t ow_loads, ow_stalls;
uint8_t ow_sx, ow_sy;

/* ring: position k + 3j (k, j = 0..2 around the center screen) -> slot; slots hold screens slot_sx/sy */
static uint8_t ring_slot[9], slot_ready[9], slot_sx[9], slot_sy[9], pending;
static int16_t ring_mx0, ring_my0;                   /* world metatile of the ring's top-left */
static uint16_t scr_x0, scr_y0;                      /* world px of the center screen's top-left */
static uint16_t drawn_tx, drawn_ty;                  /* world tile of the drawn top-left */
static uint16_t row_ty, col_tx, col_ty;              /* pending lines: where they go */
static uint8_t line_pend, scx, scy;                  /* bit 0 row, bit 1 column, bit 2 scroll */
static const uint8_t water = 0;                      /* cell outside the ring (never read in play) */

/* nearest screens first: center, edges, corners */
static const uint8_t load_order[9] = { 4, 1, 3, 5, 7, 0, 2, 6, 8 };

/* ---------- screens ---------- */

static void slot_load(uint8_t s) {
    uint8_t *d = SLOT(s), n;
    uint8_t sx = slot_sx[s], sy = slot_sy[s];
    if (sx >= WORLD_W || sy >= WORLD_H) memset(d, 0, 128);          /* past the world's edge: water, no name */
    else {
        rom_copy(d, row_ptr[sy] + sx, 128, (uint8_t)(uint16_t)row_bank[sy]);
        n = SCR_MW * SCR_MH;
        do { *d = ow_mt_lut[*d & 0x7F]; d++; } while (--n);
    }
    slot_ready[s] = 1;
    pending--;
    ow_loads++;
}

static uint8_t *slot_ptr(uint8_t pos) {             /* ring position -> screen data, loaded now if still queued */
    uint8_t s = ring_slot[pos];
    if (!slot_ready[s]) { slot_load(s); ow_stalls++; }
    return SLOT(s);
}

/* Re-centers the ring on screen (sx, sy). Screens still inside keep their slot; the freed slots get the new
   screens and are queued (loaded one per frame by ow_update). A jump of more than one screen reloads all 9. */
static void ring_center(uint8_t sx, uint8_t sy) {
    uint8_t old[9], used[9], p, k, j, s, ok, oj;
    int8_t dx = (int8_t)(sx - ow_sx), dy = (int8_t)(sy - ow_sy);
    memcpy(old, ring_slot, 9);
    memset(used, 0, 9);
    for (p = 0, j = 0; j < 3; j++) for (k = 0; k < 3; k++, p++) {
        ring_slot[p] = 0xFF;
        ok = k + dx; oj = j + dy;                    /* position in the old ring (uint8_t: -1 wraps to 255) */
        if (dx >= -1 && dx <= 1 && dy >= -1 && dy <= 1 && ok < 3 && oj < 3) {
            s = old[ok + oj + oj + oj];
            ring_slot[p] = s; used[s] = 1;
        }
    }
    for (p = 0, j = 0; j < 3; j++) for (k = 0; k < 3; k++, p++) {
        if (ring_slot[p] != 0xFF) continue;
        for (s = 0; used[s]; s++) ;
        used[s] = 1;
        ring_slot[p] = s;
        slot_sx[s] = sx + k - 1;                     /* -1 wraps to 255: outside the world */
        slot_sy[s] = sy + j - 1;
        if (slot_ready[s]) { slot_ready[s] = 0; pending++; }
    }
    ow_sx = sx; ow_sy = sy;
    ring_mx0 = (int16_t)(sx - 1) * SCR_MW;
    ring_my0 = (int16_t)(sy - 1) * SCR_MH;
    scr_x0 = (uint16_t)sx * 160;
    scr_y0 = (uint16_t)sy * 144;
}

/* cell (metatile id) at world px; the 4 queries of a collision rect cost ~1,000 cycles in all */
static const uint8_t *cell_at(uint16_t px, uint16_t py) {
    int16_t rx = (int16_t)(px >> 4) - ring_mx0, ry = (int16_t)(py >> 4) - ring_my0;
    uint8_t k = 0, j = 0, mx, my;
    if ((uint16_t)rx >= 3 * SCR_MW || (uint16_t)ry >= 3 * SCR_MH) return &water;
    mx = (uint8_t)rx; my = (uint8_t)ry;
    if (mx >= SCR_MW) { mx -= SCR_MW; k++; if (mx >= SCR_MW) { mx -= SCR_MW; k++; } }
    if (my >= SCR_MH) { my -= SCR_MH; j += 3; if (my >= SCR_MH) { my -= SCR_MH; j += 3; } }
    return slot_ptr(k + j) + (uint8_t)((my << 3) + my + my) + mx;
}

uint8_t ow_coll(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1) BANKED {
    return ow_mt_coll[*cell_at(x0, y0)] | ow_mt_coll[*cell_at(x1, y0)] |
           ow_mt_coll[*cell_at(x0, y1)] | ow_mt_coll[*cell_at(x1, y1)];
}

uint8_t ow_tag(uint16_t x, uint16_t y) BANKED { return ow_mt_tag[*cell_at(x, y)]; }

const char *ow_sign(uint16_t x, uint16_t y) BANKED {   /* slots are 128-byte aligned: base = cell & ~127 */
    const uint8_t *c = cell_at(x, y);
    if (c == &water) return 0;                          /* a literal here would live in this bank */
    return (const char *)(((uint16_t)c & 0xFF80) + SIGN_OFS);
}

const char *ow_name(void) BANKED { return (const char *)(slot_ptr(4) + NAME_OFS); }

uint8_t ow_bank(void) BANKED { return (uint8_t)(uint16_t)row_bank[ow_sy]; }

/* ---------- BG streaming (same scheme as the engine's map module, docs/engine-api.md 7.6) ---------- */

static void vram_row(uint8_t *d, const uint8_t *s, uint8_t n) {
    do { while (STAT_REG & STATF_BUSY); *d++ = *s++; } while (--n);
}
static void vram_col(uint8_t *d, const uint8_t *s, uint8_t n) {
    do { while (STAT_REG & STATF_BUSY); *d = *s++; d += 32; } while (--n);
}

static void row_write(void) {
    uint8_t *d = (uint8_t *)0x9800 + ((uint16_t)(row_ty & 31) << 5), *b = ow_row_buf;
    if ((uint8_t)(LY_REG - 144) < 9) {          /* VBlank: GDMA, 2 x 32 bytes */
        HDMA3_REG = (uint16_t)d >> 8; HDMA4_REG = (uint8_t)(uint16_t)d;
        HDMA1_REG = (uint16_t)b >> 8; HDMA2_REG = (uint8_t)(uint16_t)b;
        VBK_REG = 0; HDMA5_REG = 1;
        b += 32;
        HDMA3_REG = (uint16_t)d >> 8; HDMA4_REG = (uint8_t)(uint16_t)d;
        HDMA1_REG = (uint16_t)b >> 8; HDMA2_REG = (uint8_t)(uint16_t)b;
        VBK_REG = 1; HDMA5_REG = 1;
        VBK_REG = 0;
    } else {                                    /* screen being drawn: byte by byte in HBlank */
        VBK_REG = 1; vram_row(d, b + 32, 32);
        VBK_REG = 0; vram_row(d, b, 32);
    }
    line_pend &= ~1;
}

static void col_write(void) {                  /* split where the 32x32 BG map wraps */
    uint8_t x = col_tx & 31, y = col_ty & 31, k = 32 - y;
    uint8_t *d = (uint8_t *)0x9800 + ((uint16_t)y << 5) + x, *top = (uint8_t *)0x9800 + x;
    if (k > 19) k = 19;
    VBK_REG = 1; vram_col(d, ow_col_a, k); if (k < 19) vram_col(top, ow_col_a + k, 19 - k);
    VBK_REG = 0; vram_col(d, ow_col_t, k); if (k < 19) vram_col(top, ow_col_t + k, 19 - k);
    line_pend &= ~2;
}

void ow_flush(void) BANKED {
    if (line_pend & 4) move_bkg(scx, scy);
    if (line_pend & 1) row_write();
    if (line_pend & 2) col_write();
    line_pend = 0;
}

/* id << 2 | quadrant for n cells of one screen: along a metatile row (quadrant bit 0 = right half) or down a
   metatile column (bit 1 = bottom half). One pointer per loop keeps SDCC in registers. */
static void row_cells(uint8_t *o, const uint8_t *p, uint8_t q, uint8_t n) {
    do { *o++ = (uint8_t)(*p << 2) | q; if (q & 1) p++; q ^= 1; } while (--n);
}
static void col_cells(uint8_t *o, const uint8_t *p, uint8_t q, uint8_t n) {
    do { *o++ = (uint8_t)(*p << 2) | q; if (q & 2) p += SCR_MW; q ^= 2; } while (--n);
}
static void xlat_tile(uint8_t *b, uint8_t n) { do { *b = ow_mt_tile[*b]; b++; } while (--n); }
static void xlat_attr(uint8_t *b, uint8_t n) { do { *b = ow_mt_attr[*b]; b++; } while (--n); }

/* ring-relative tile coordinate -> screen index 0..2 (3 = outside) and tile inside it */
static uint8_t split(int16_t r, uint8_t size, uint8_t *local) {
    uint8_t n = 0;
    if ((uint16_t)r >= 3 * size) return 3;
    while ((uint8_t)r >= size) { r -= size; n++; }
    *local = (uint8_t)r;
    return n;
}

/* row of 21 tiles from world tile (tx0, ty): spans at most 2 screens across */
static void gather_row(uint16_t tx0, uint16_t ty) {
    uint8_t lx = 0, ly = 0, k, j, seg, n = 21, x, *o = ow_line;
    const uint8_t *p;
    if (line_pend & 1) row_write();             /* a second row before a flush: write the first now */
    row_ty = ty;
    k = split((int16_t)tx0 - (ring_mx0 << 1), SCR_MW * 2, &lx);
    j = split((int16_t)ty - (ring_my0 << 1), SCR_MH * 2, &ly);
    for (;;) {
        seg = SCR_MW * 2 - lx; if (seg > n) seg = n;
        if (k > 2 || j > 2) memset(o, 0, seg);
        else {
            p = slot_ptr(k + j + j + j) + (uint8_t)((ly >> 1) * SCR_MW) + (lx >> 1);
            row_cells(o, p, ((ly & 1) << 1) | (lx & 1), seg);
        }
        o += seg; n -= seg;
        if (!n) break;
        lx = 0; k++;
    }
    x = tx0 & 31;
    n = 32 - x; if (n > 21) n = 21;             /* cells before the BG map wraps */
    memcpy(ow_row_buf + x, ow_line, n); xlat_tile(ow_row_buf + x, n);
    memcpy(ow_row_buf + 32 + x, ow_line, n); xlat_attr(ow_row_buf + 32 + x, n);
    if (n < 21) {
        memcpy(ow_row_buf, ow_line + n, 21 - n); xlat_tile(ow_row_buf, 21 - n);
        memcpy(ow_row_buf + 32, ow_line + n, 21 - n); xlat_attr(ow_row_buf + 32, 21 - n);
    }
    line_pend |= 1;
}

/* column of 19 tiles from world tile (tx, ty0): spans at most 2 screens down */
static void gather_col(uint16_t tx, uint16_t ty0) {
    uint8_t lx = 0, ly = 0, k, j, seg, n = 19, *o = ow_line;
    const uint8_t *p;
    if (line_pend & 2) col_write();
    col_tx = tx; col_ty = ty0;
    k = split((int16_t)tx - (ring_mx0 << 1), SCR_MW * 2, &lx);
    j = split((int16_t)ty0 - (ring_my0 << 1), SCR_MH * 2, &ly);
    for (;;) {
        seg = SCR_MH * 2 - ly; if (seg > n) seg = n;
        if (k > 2 || j > 2) memset(o, 0, seg);
        else {
            p = slot_ptr(k + j + j + j) + (uint8_t)((ly >> 1) * SCR_MW) + (lx >> 1);
            col_cells(o, p, ((ly & 1) << 1) | (lx & 1), seg);
        }
        o += seg; n -= seg;
        if (!n) break;
        ly = 0; j++;
    }
    memcpy(ow_col_t, ow_line, 19); xlat_tile(ow_col_t, 19);
    memcpy(ow_col_a, ow_line, 19); xlat_attr(ow_col_a, 19);
    line_pend |= 2;
}

static void cam_center(uint16_t px, uint16_t py) {
    int16_t x = (int16_t)px - 80, y = (int16_t)py - OW_VIEW_H / 2;
    ow_cam_x = CLAMP(x, 0, WORLD_W * 160 - 160);
    ow_cam_y = CLAMP(y, 0, WORLD_H * 144 - OW_VIEW_H);
}

static void cam_apply(void) {
    uint16_t tx = (uint16_t)ow_cam_x >> 3, ty = (uint16_t)ow_cam_y >> 3;
    while (drawn_tx < tx) { drawn_tx++; gather_col(drawn_tx + 20, drawn_ty); }
    while (drawn_tx > tx) { drawn_tx--; gather_col(drawn_tx, drawn_ty); }
    while (drawn_ty < ty) { drawn_ty++; gather_row(drawn_tx, drawn_ty + 18); }
    while (drawn_ty > ty) { drawn_ty--; gather_row(drawn_tx, drawn_ty); }
    scx = (uint8_t)ow_cam_x; scy = (uint8_t)ow_cam_y;
    line_pend |= 4;
}

void ow_update(uint16_t px, uint16_t py) BANKED {
    uint8_t sx = ow_sx, sy = ow_sy, i, s;
    if (px < scr_x0) sx--; else if (px >= scr_x0 + 160) sx++;
    if (py < scr_y0) sy--; else if (py >= scr_y0 + 144) sy++;
    if (sx != ow_sx || sy != ow_sy) ring_center(sx, sy);
    cam_center(px, py);
    cam_apply();
    if (pending) for (i = 0; i < 9; i++) {          /* one queued screen per frame */
        s = ring_slot[load_order[i]];
        if (!slot_ready[s]) { slot_load(s); break; }
    }
}

/* ---------- scene start ---------- */

void ow_init(uint16_t px, uint16_t py) BANKED {
    const ow_metatile_t *m;
    uint8_t i, q, n, bank = BANK(ts_overworld);
    /* the tileset lives in another bank: stage it in the slot memory (free until the ring loads) */
    for (i = 0; i < OW_TILES; i += n) {
        n = OW_TILES - i; if (n > 64) n = 64;
        rom_copy(SLOT_MEM, ts_overworld_tiles + ((uint16_t)i << 4), (uint16_t)n << 4, bank);
        VBK_REG = 0;
        set_bkg_data(128 + i, n, SLOT_MEM);
    }
    rom_copy(SLOT_MEM, ts_overworld_pals, 7 * 4 * sizeof(palette_color_t), bank);
    for (i = 0; i < 7; i++) gfx_set_bkg_palette(i, (const palette_color_t *)SLOT_MEM + (i << 2));
    rom_copy(SLOT_MEM, ow_metatiles, OW_METATILES * sizeof(ow_metatile_t), bank);
    memset(ow_mt_lut, 0, 128);
    memset(ow_mt_tile, 128, 128);
    memset(ow_mt_attr, 0, 128);
    for (i = 0, m = (const ow_metatile_t *)SLOT_MEM; i < OW_METATILES; i++, m++) {
        ow_mt_lut[(uint8_t)m->ch & 0x7F] = i;
        for (q = 0; q < 4; q++) {
            ow_mt_tile[(i << 2) | q] = 128 + m->tile[q];
            ow_mt_attr[(i << 2) | q] = m->attr[q];
        }
        ow_mt_coll[i] = m->coll;
        ow_mt_tag[i] = m->tag;
    }
    /* ring: all 9 screens now */
    for (i = 0; i < 9; i++) { ring_slot[i] = i; slot_ready[i] = 1; }
    pending = 0;
    ow_sx = ow_sy = 0x80;                           /* far from any screen: ring_center reloads all 9 */
    ring_center((uint8_t)(px / 160), (uint8_t)(py / 144));
    for (i = 0; i < 9; i++) slot_load(i);
    ow_loads = ow_stalls = 0;
    /* whole screen */
    cam_center(px, py);
    drawn_tx = (uint16_t)ow_cam_x >> 3; drawn_ty = (uint16_t)ow_cam_y >> 3;
    line_pend = 0;
    for (i = 0; i < 19; i++) gather_row(drawn_tx, drawn_ty + i);
    cam_apply();
    ow_flush();
}
