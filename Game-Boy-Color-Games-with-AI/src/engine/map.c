#include "engine/engine.h"
#include <string.h>

static uint8_t lut_tile[128], lut_attr[128], lut_coll[128], lut_tag[128];
static const char * const *map_rows;
static uint8_t map_w, map_h;                   /* tiles; every tile coordinate fits in 8 bits (<= 200) */
static uint8_t map_bank;
uint16_t map_w_px, map_h_px;

int16_t cam_x, cam_y;
static uint8_t drawn_tx, drawn_ty;    /* tile of the currently drawn top-left */
static uint8_t shake_t, shake_s;
/* Streaming: cam_follow gathers each new row (21 cells right) / column (19 cells down) into RAM, map_flush
   writes them and the scroll at the start of the next frame, in VBlank. Written cell by cell while the screen
   is drawn, where every VRAM byte waits for HBlank, a line cost ~39,000 cycles.
   The row buffer is laid out like a BG map row: cell x at x & 31, attributes 32 bytes after the tiles. The 11
   cells off screen keep what earlier rows left there (a column is always drawn whole before it shows), so in
   VBlank the flush copies the row with one GDMA per VRAM bank. GDMA needs a 16-byte aligned source and SDCC
   can't align a static: ROW_BUF is the first 32-byte boundary inside row_mem. */
static uint8_t row_mem[64 + 31];
#define ROW_BUF ((uint8_t *)(((uint16_t)row_mem + 31) & 0xFFE0))
static uint8_t col_t[19], col_a[19];            /* column: tiles, attributes */
static uint8_t row_mx, row_my, col_mx, col_my;  /* map cell of each line's first cell */
static uint8_t line_pend, scx, scy;             /* bit 0 row, bit 1 column, bit 2 scroll */

void map_load(const map_def_t *m, uint8_t bank) {
    const map_legend_t *l;
    const tileset_def_t *ts;
    uint8_t i, c;
    uint8_t save = CURRENT_BANK;
    map_bank = bank;
    if (bank) SWITCH_ROM(bank);
    for (i = 0; i < 128; i++) { lut_tile[i] = TILE_BLANK; lut_attr[i] = ATTR_BLANK; lut_coll[i] = 0; lut_tag[i] = 0; }
    for (l = m->legend; l->ch; l++) {
        c = (uint8_t)l->ch & 0x7F;
        lut_tile[c] = 128 + l->tile;
        lut_attr[c] = l->pal & 0xE7;          /* palette, flips, MAP_OVER priority; bit 3 (VRAM bank) dropped */
        lut_coll[c] = l->coll;
        lut_tag[c] = l->tag;
    }
    map_w = m->w; map_h = m->h; map_rows = m->rows;
    map_w_px = map_w << 3; map_h_px = map_h << 3;
    ts = m->tileset;
    VBK_REG = 0;
    set_bkg_data(128, ts->count, ts->tiles);
    for (i = 0; i < ts->pal_count; i++) gfx_set_bkg_palette(i, ts->pals[i]);
    if (bank) SWITCH_ROM(save);
}

char map_char(uint16_t tx, uint16_t ty) {
    char c;
    uint8_t save = CURRENT_BANK;
    if (map_bank) SWITCH_ROM(map_bank);
    c = map_rows[(uint8_t)ty][(uint8_t)tx] & 0x7F;
    if (map_bank) SWITCH_ROM(save);
    return c;
}

uint8_t map_coll(uint16_t tx, uint16_t ty) {
    if (tx >= map_w) return COLL_SOLID;
    if (ty >= map_h) return 0;
    return lut_coll[(uint8_t)map_char(tx, ty)];
}

uint8_t map_coll_px(int16_t px, int16_t py) {
    if (px < 0 || py < 0) return COLL_SOLID;
    return map_coll((uint16_t)px >> 3, (uint16_t)py >> 3);
}

uint8_t map_tag(uint16_t tx, uint16_t ty) {
    if (tx >= map_w || ty >= map_h) return 0;
    return lut_tag[(uint8_t)map_char(tx, ty)];
}

/* OR of rq_lut[] over every cell of the pixel rect x0..x1, y0..y1 (x0 <= x1, y0 <= y1). A rect that reaches
   left of, right of or above the map returns rq_out alone (COLL_SOLID: those edges are walls, so a body is never
   partly there); cells below the map are open (0). One bank switch, then walks the row strings (a map_char per
   cell costs ~450 cycles). The unsigned compares catch negative and past-the-edge coords at once. */
static const uint8_t *rq_lut = lut_coll;          /* map_tag_rect swaps in lut_tag and 0 for its call */
static uint8_t rq_out = COLL_SOLID;
uint8_t map_coll_rect(int16_t x0, int16_t y0, int16_t x1, int16_t y1) {
    const char * const *r;
    const char *p;
    uint8_t f = 0, tx, w, h, n;
    uint8_t save = CURRENT_BANK;
    if ((uint16_t)x0 >= map_w_px || (uint16_t)x1 >= map_w_px || y0 < 0) return rq_out;
    if ((uint16_t)y1 >= map_h_px) {                  /* reaches below the map */
        if ((uint16_t)y0 >= map_h_px) return 0;
        y1 = map_h_px - 1;
    }
    tx = (uint16_t)x0 >> 3;
    w = (uint8_t)((uint16_t)x1 >> 3) - tx;         /* cells - 1 */
    n = (uint16_t)y0 >> 3;
    h = (uint8_t)((uint16_t)y1 >> 3) - n;
    r = map_rows + n;
    if (map_bank) SWITCH_ROM(map_bank);
    for (;;) {
        p = *r + tx;
        n = w;
        for (;;) {
            f |= rq_lut[(uint8_t)*p & 0x7F];
            if (!n) break;
            n--; p++;
        }
        if (!h) break;
        h--; r++;
    }
    if (map_bank) SWITCH_ROM(save);
    return f;
}

uint8_t map_tag_rect(int16_t x0, int16_t y0, int16_t x1, int16_t y1) {
    uint8_t f;
    rq_lut = lut_tag; rq_out = 0;
    f = map_coll_rect(x0, y0, x1, y1);
    rq_lut = lut_coll; rq_out = COLL_SOLID;
    return f;
}

/* n-th cell (row by row) whose char is ch or has a tag bit of mask; ch 0x80 never matches. One bank switch. */
static uint8_t map_scan(uint8_t ch, uint8_t mask, uint8_t n, uint16_t *tx, uint16_t *ty) {
    const char *p;
    uint8_t x, y, c, found = 0;
    uint8_t save = CURRENT_BANK;
    if (map_bank) SWITCH_ROM(map_bank);
    for (y = 0; y < map_h && !found; y++) {
        p = map_rows[y];
        for (x = 0; x < map_w; x++) {
            c = (uint8_t)*p++ & 0x7F;
            if (c != ch && !(lut_tag[c] & mask)) continue;
            if (n) { n--; continue; }
            *tx = x; *ty = y; found = 1;
            break;
        }
    }
    if (map_bank) SWITCH_ROM(save);
    return found;
}

uint8_t map_find(char ch, uint8_t n, uint16_t *tx, uint16_t *ty) {
    return map_scan((uint8_t)ch, 0, n, tx, ty);
}

uint8_t map_find_tag(uint8_t mask, uint8_t n, uint16_t *tx, uint16_t *ty) {
    return map_scan(0x80, mask, n, tx, ty);
}

static void put_raw(uint16_t mx, uint16_t my, uint8_t t, uint8_t a) {
    VBK_REG = 1; set_bkg_tile_xy(mx & 31, my & 31, a);
    VBK_REG = 0; set_bkg_tile_xy(mx & 31, my & 31, t);
}

void map_set_tile(uint16_t tx, uint16_t ty, char ch) {
    uint8_t c = (uint8_t)ch & 0x7F, t = lut_tile[c], a = lut_attr[c];
    uint8_t i;
    if (tx < drawn_tx || tx > drawn_tx + 20 || ty < drawn_ty || ty > drawn_ty + 18) return;
    /* a pending line would overwrite the cell at the next map_flush: patch it too */
    if ((line_pend & 1) && (uint8_t)ty == row_my && (uint8_t)((uint8_t)tx - row_mx) < 21) {
        i = tx & 31; ROW_BUF[i] = t; ROW_BUF[i + 32] = a;
    }
    if ((line_pend & 2) && (uint8_t)tx == col_mx && (i = (uint8_t)ty - col_my) < 19) { col_t[i] = t; col_a[i] = a; }
    put_raw(tx, ty, t, a);
}

/* ---------- camera + streaming (the BG map is 32x32 and wraps) ---------- */

/* n bytes to VRAM along a BG map row / down a column. Not set_bkg_tiles: it costs ~250 cycles per byte even in
   VBlank, so a line ran past VBlank and then waited for HBlank on every byte. Same VRAM wait as GBDK (none in
   VBlank). Small separate functions so SDCC keeps the pointers in registers: ~105 / ~130 cycles per byte. */
static void vram_row(uint8_t *d, const uint8_t *s, uint8_t n) {
    do { while (STAT_REG & STATF_BUSY); *d++ = *s++; } while (--n);
}
static void vram_col(uint8_t *d, const uint8_t *s, uint8_t n) {
    do { while (STAT_REG & STATF_BUSY); *d = *s++; d += 32; } while (--n);
}

static void row_write(void) {
    uint8_t *d = (uint8_t *)0x9800 + ((uint16_t)(row_my & 31) << 5), *b = ROW_BUF;
    if ((uint8_t)(LY_REG - 144) < 9) {          /* VBlank (LY 144-152): GDMA, 2 x 16 bytes, the CPU waits ~260 cycles */
        HDMA3_REG = (uint16_t)d >> 8; HDMA4_REG = (uint8_t)(uint16_t)d;
        HDMA1_REG = (uint16_t)b >> 8; HDMA2_REG = (uint8_t)(uint16_t)b;
        VBK_REG = 0; HDMA5_REG = 1;
        b += 32;
        HDMA3_REG = (uint16_t)d >> 8; HDMA4_REG = (uint8_t)(uint16_t)d;
        HDMA1_REG = (uint16_t)b >> 8; HDMA2_REG = (uint8_t)(uint16_t)b;
        VBK_REG = 1; HDMA5_REG = 1;
        VBK_REG = 0;
    } else {                                    /* while the screen is drawn: byte by byte, waiting for HBlank */
        VBK_REG = 1; vram_row(d, b + 32, 32);
        VBK_REG = 0; vram_row(d, b, 32);
    }
    line_pend &= ~1;
}

static void col_write(void) {                  /* split where the 32x32 BG map wraps */
    uint8_t x = col_mx & 31, y = col_my & 31, k = 32 - y;
    uint8_t *d = (uint8_t *)0x9800 + ((uint16_t)y << 5) + x, *top = (uint8_t *)0x9800 + x;
    if (k > 19) k = 19;
    VBK_REG = 1; vram_col(d, col_a, k); if (k < 19) vram_col(top, col_a + k, 19 - k);
    VBK_REG = 0; vram_col(d, col_t, k); if (k < 19) vram_col(top, col_t + k, 19 - k);
    line_pend &= ~2;
}

void map_flush(void) {
    if (line_pend & 4) move_bkg(scx, scy);
    if (line_pend & 1) row_write();
    if (line_pend & 2) col_write();
    line_pend = 0;
}

/* Gathering a line: copy its map chars, then translate them in place through one table at a time. Each loop
   holds one or two pointers, which SDCC keeps in registers (~64 cycles per cell and table); a loop reading
   both tables spilled everything to the stack (~630). Char 0 has no legend entry: blank cells. */
static void xlat_tile(uint8_t *b, uint8_t n) { do { *b = lut_tile[*b]; b++; } while (--n); }
static void xlat_attr(uint8_t *b, uint8_t n) { do { *b = lut_attr[*b]; b++; } while (--n); }
static void row_chars(uint8_t *t, const char *p, uint8_t n) { do *t++ = (uint8_t)*p++ & 0x7F; while (--n); }
static uint8_t col_x;                           /* column of col_chars: a static keeps the loop in registers */
static void col_chars(uint8_t *t, const char * const *r, uint8_t n) { do *t++ = (uint8_t)(*r++)[col_x] & 0x7F; while (--n); }

static uint8_t line_c[21];                      /* chars of the line being gathered */

static void row_put(uint8_t x, const uint8_t *c, uint8_t n) {   /* n cells to the row buffer at x, no wrap */
    uint8_t *b = ROW_BUF + x;
    memcpy(b, c, n); xlat_tile(b, n);
    memcpy(b + 32, c, n); xlat_attr(b + 32, n);
}

static void draw_row(uint8_t mx, uint8_t my) {
    uint8_t n = 0, k, save = CURRENT_BANK;
    if (line_pend & 1) row_write();             /* a second row before a flush: write the first now */
    row_mx = mx; row_my = my;
    if (mx < map_w && my < map_h) {             /* cells inside the map: one bank switch */
        n = map_w - mx; if (n > 21) n = 21;
        if (map_bank) SWITCH_ROM(map_bank);
        row_chars(line_c, map_rows[my] + mx, n);
        if (map_bank) SWITCH_ROM(save);
    }
    if (n < 21) memset(line_c + n, 0, 21 - n);
    mx &= 31;
    k = 32 - mx; if (k > 21) k = 21;            /* cells before the buffer (and the BG map) wraps */
    row_put(mx, line_c, k);
    if (k < 21) row_put(0, line_c + k, 21 - k);
    line_pend |= 1;
}

static void draw_col(uint8_t mx, uint8_t my) {
    uint8_t n = 0, save = CURRENT_BANK;
    if (line_pend & 2) col_write();
    col_mx = mx; col_my = my;
    if (mx < map_w && my < map_h) {
        n = map_h - my; if (n > 19) n = 19;
        col_x = mx;
        if (map_bank) SWITCH_ROM(map_bank);
        col_chars(col_t, map_rows + my, n);
        if (map_bank) SWITCH_ROM(save);
    }
    if (n < 19) memset(col_t + n, 0, 19 - n);
    memcpy(col_a, col_t, 19);
    xlat_tile(col_t, 19); xlat_attr(col_a, 19);
    line_pend |= 2;
}

static int16_t clamp_cam(int16_t v, int16_t hi) {   /* 0..hi, and 0 when the map is smaller than the screen */
    if (v > hi) v = hi;
    return v < 0 ? 0 : v;
}

static void cam_clamp(void) {
    cam_x = clamp_cam(cam_x, (int16_t)map_w_px - 160);
    cam_y = clamp_cam(cam_y, (int16_t)map_h_px - 144);
}

/* Shake offset from a random nibble r, -shake_s..shake_s, kept inside the drawn cells: they cover the scroll
   drawn * 8 + 0..8 and f is the camera's pixel inside its tile, so the offset must stay in -f..8-f (a column or
   row outside was never drawn, and left of / above the map the scroll wrapped to the far side of the BG map).
   Out of range it is mirrored first, so the screen still shakes both ways when there is room. */
static int8_t shake_off(uint8_t r, uint8_t f) {
    int8_t d, lo = -(int8_t)f, hi = 8 - (int8_t)f;
    uint8_t span = shake_s << 1;
    while (r > span) r -= span + 1;             /* no % library call */
    d = (int8_t)r - (int8_t)shake_s;
    if (d < lo || d > hi) d = -d;
    return d < lo ? lo : d > hi ? hi : d;
}

static void cam_apply(void) {          /* after cam_x/cam_y changed and were clamped */
    uint8_t tx = (uint16_t)cam_x >> 3, ty = (uint16_t)cam_y >> 3, r;
    int8_t dx = 0, dy = 0;
    while (drawn_tx < tx) { drawn_tx++; draw_col(drawn_tx + 20, drawn_ty); }
    while (drawn_tx > tx) { drawn_tx--; draw_col(drawn_tx,      drawn_ty); }
    while (drawn_ty < ty) { drawn_ty++; draw_row(drawn_tx, drawn_ty + 18); }
    while (drawn_ty > ty) { drawn_ty--; draw_row(drawn_tx, drawn_ty); }
    if (shake_t) {                              /* one random byte: a nibble per axis */
        shake_t--;
        r = rand();
        dx = shake_off(r & 15, (uint8_t)cam_x & 7);
        dy = shake_off(r >> 4, (uint8_t)cam_y & 7);
    }
    scx = (uint8_t)cam_x + dx; scy = (uint8_t)cam_y + dy;
    line_pend |= 4;
}

void cam_set(int16_t x, int16_t y) {
    uint8_t i;
    cam_x = x; cam_y = y;
    cam_clamp();
    drawn_tx = (uint16_t)cam_x >> 3; drawn_ty = (uint16_t)cam_y >> 3;
    for (i = 0; i < 19; i++) draw_row(drawn_tx, drawn_ty + i);
    cam_apply();
    map_flush();                            /* scene start: the whole screen now */
}

static int16_t follow_step(int16_t d) {   /* d = target - camera: 8 px dead zone, then at most 8 px per frame */
    if (d > 16) return 8;
    if (d > 8) return d - 8;
    if (d < -16) return -8;
    if (d < -8) return d + 8;
    return 0;
}

void cam_follow(int16_t wx, int16_t wy) {
    cam_x += follow_step(wx - 80 - cam_x);
    cam_y += follow_step(wy - 72 - cam_y);
    cam_clamp();
    cam_apply();
}

void cam_shake(uint8_t frames, uint8_t strength) { shake_t = frames; shake_s = strength > 7 ? 7 : strength; }

void cam_reset(void) {
    cam_x = cam_y = 0;
    drawn_tx = drawn_ty = 0;
    shake_t = 0;
    line_pend = 0;
    map_w = map_h = 0; map_w_px = map_h_px = 0;
}
