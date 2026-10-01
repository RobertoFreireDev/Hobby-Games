# Engine API

Read when: writing game code or scenes that call the engine, or changing `src/engine/`. The audio module (7.13) is in [audio.md](audio.md).

## 7. Engine API

Build the engine exactly with these names and semantics. Reference code is given where correctness is subtle; write the rest in the same style.

### 7.1 core (core.h / core.c)

```c
#include <gb/gb.h>
#include <gb/cgb.h>
#include <stdint.h>
#include <rand.h>
#include <gbdk/emu_debug.h>

/* fixed point 12.4 in int16_t: 1 pixel = 16 units, range ±2047 px */
#define FIX(px)     ((int16_t)((px) << 4))
#define UNFIX(v)    ((int16_t)(v) >> 4)
#define ABS(a)      ((a) < 0 ? -(a) : (a))
#define MIN(a,b)    ((a) < (b) ? (a) : (b))
#define MAX(a,b)    ((a) > (b) ? (a) : (b))
#define CLAMP(v,lo,hi) ((v) < (lo) ? (lo) : ((v) > (hi) ? (hi) : (v)))

void engine_init(void);
int16_t approach(int16_t v, int16_t target, int16_t step);  /* move v toward target by step */
void rand_seed(void);     /* initrand(DIV_REG | (sys_time << 8)); call when the player presses START */
```
`engine_init()`:
```c
void engine_init(void) {
    if (_cpu != CGB_TYPE) { while (1) vsync(); }   /* Color only */
    cpu_fast();
    DISPLAY_OFF;                 /* the only allowed DISPLAY_OFF */
    SPRITES_8x8;
    fade_init();                 /* all palettes in RAM, fade level = fully black */
    scene_reset_screen();        /* clear BG map + attributes, hide sprites/window */
    text_init();                 /* font + box tiles into VRAM bank 1, default UI palette */
    audio_init();                /* sound on, add_VBL(audio_update) */
    SHOW_BKG; SHOW_SPRITES; HIDE_WIN;
    DISPLAY_ON;
}
```

### 7.2 input

```c
extern uint8_t keys, keys_prev;
void input_update(void);                       /* keys_prev = keys; keys = joypad(); */
#define KEY_HELD(k)     (keys & (k))
#define KEY_PRESSED(k)  ((keys & (k)) && !(keys_prev & (k)))
#define KEY_RELEASED(k) (!(keys & (k)) && (keys_prev & (k)))
/* k: J_UP J_DOWN J_LEFT J_RIGHT J_A J_B J_START J_SELECT (can be OR-ed) */
uint8_t input_wait_press(uint8_t mask);        /* blocking; returns the key pressed */
```

### 7.3 gfx (palettes + sprite loading)

```c
typedef struct { uint8_t base, w, h, tpf, frames, pal; } sprite_t;   /* RAM handle (tpf = tiles per frame) */

void gfx_set_bkg_palette(uint8_t slot, const palette_color_t *c4);  /* goes through fade (7.10) */
void gfx_set_obj_palette(uint8_t slot, const palette_color_t *c4);
uint8_t gfx_load_sprite(sprite_t *out, const sprite_def_t *def, uint8_t bank);
    /* copies tiles into bank-0 VRAM at next free index (0..127), loads palette into def->pal_slot,
       fills *out, returns 0 if VRAM is full. bank = 0 for non-banked data (section 10, docs/banking.md) */
void gfx_reset(void);                     /* sprite VRAM allocator back to 0 (called on scene change) */
```
Loading the same `sprite_def_t` twice wastes VRAM — load each once per scene and share the handle.

### 7.4 sprites (OAM allocator + drawing)

```c
void spr_begin(void);                          /* called by scene_update */
void spr_end(void);                            /* hides OAM entries not used this frame */
uint8_t spr_put(uint8_t tile, int16_t sx, int16_t sy, uint8_t prop);   /* one 8x8, screen coords */
void spr_draw(const sprite_t *s, uint8_t frame, int16_t sx, int16_t sy, uint8_t flags);
void spr_hide_all(void);
#define SPR_FLIPX 0x20
#define SPR_FLIPY 0x40
#define SPR_BEHIND 0x80
```
Reference:
```c
static uint8_t spr_next, spr_last;
void spr_begin(void) { spr_next = 0; }
void spr_end(void) {
    uint8_t i;
    for (i = spr_next; i < spr_last; i++) hide_sprite(i);
    spr_last = spr_next;
}
uint8_t spr_put(uint8_t tile, int16_t sx, int16_t sy, uint8_t prop) {
    volatile OAM_item_t *o;
    /* visible when -8 < sx < 160 and -8 < sy < 144: one unsigned compare per axis */
    if (spr_next >= 40 || (uint16_t)(sx + 7) >= 167 || (uint16_t)(sy + 7) >= 151) return 0;
    o = &shadow_OAM[spr_next++];              /* written directly: set_sprite_* + move_sprite cost ~50% more */
    o->y = (uint8_t)sy + 16;
    o->x = (uint8_t)sx + 8;
    o->tile = tile;
    o->prop = prop;
    return 1;
}
void spr_draw(const sprite_t *s, uint8_t frame, int16_t sx, int16_t sy, uint8_t flags) {
    uint8_t r, c, t, w = s->w, h = s->h;
    uint8_t row = s->base + frame * s->tpf;       /* tile drawn at the top-left */
    uint8_t row_step = w, col_step = 1;           /* uint8_t wraps: 0 - w steps back */
    uint8_t prop = s->pal | flags;
    int16_t x;
    if (flags & SPR_FLIPY) { row += (uint8_t)((h - 1) * w); row_step = (uint8_t)(0 - w); }
    if (flags & SPR_FLIPX) { row += w - 1; col_step = 0xFF; }
    for (r = 0; r < h; r++, sy += 8, row += row_step)
        for (c = 0, t = row, x = sx; c < w; c++, x += 8, t += col_step) spr_put(t, x, sy, prop);
}
```
Draw order = priority: sprites drawn **first appear on top**. Draw the player (and UI cursor) before enemies and particles.

### 7.5 anim

```c
typedef struct { const uint8_t *frames; uint8_t len; uint8_t speed; uint8_t loop; } anim_def_t; /* speed = frames per step */
typedef struct { const anim_def_t *def; uint8_t i, timer, done; } anim_t;
void anim_play(anim_t *a, const anim_def_t *def);   /* restarts only if def changed */
void anim_update(anim_t *a);                        /* once per frame */
#define anim_frame(a) ((a)->def->frames[(a)->i])
```
Defined in game code:
```c
static const uint8_t walk_frames[] = { 0, 1, 0, 2 };
static const anim_def_t anim_walk = { walk_frames, 4, 8, 1 };
```

### 7.6 map + camera

```c
void map_load(const map_def_t *m, uint8_t bank);   /* builds lookup tables, loads tileset (BG 128+) and BG palettes */
char    map_char(uint16_t tx, uint16_t ty);
uint8_t map_coll(uint16_t tx, uint16_t ty);        /* COLL_* bits; outside left/right/top = COLL_SOLID, below = 0 */
uint8_t map_coll_px(int16_t px, int16_t py);       /* same, world pixel coords */
uint8_t map_coll_rect(int16_t x0, int16_t y0, int16_t x1, int16_t y1);  /* OR of every cell the pixel rect covers */
uint8_t map_tag(uint16_t tx, uint16_t ty);         /* legend tag; 0 outside the map */
uint8_t map_tag_rect(int16_t x0, int16_t y0, int16_t x1, int16_t y1);   /* OR of every cell the pixel rect covers */
uint8_t map_find(char ch, uint8_t n, uint16_t *tx, uint16_t *ty);  /* n-th occurrence, returns 0 if none */
uint8_t map_find_tag(uint8_t mask, uint8_t n, uint16_t *tx, uint16_t *ty);  /* n-th cell with any tag bit of mask */
void    map_set_tile(uint16_t tx, uint16_t ty, char ch);  /* changes the VRAM tile only (visual: open door, collected coin);
                                                            keep game-side state for logic */
extern uint16_t map_w_px, map_h_px;

extern int16_t cam_x, cam_y;                       /* world pixel of screen top-left */
void cam_set(int16_t x, int16_t y);                /* clamp + redraw full screen now (use at scene start) */
void cam_follow(int16_t wx, int16_t wy);           /* center on point with small dead zone, clamp, stream */
void map_flush(void);    /* writes what cam_follow streamed + the scroll; scene_update calls it after vsync */
void cam_shake(uint8_t frames, uint8_t strength);  /* applied by cam_follow */
void cam_reset(void);                              /* called by the scene manager */
#define W2S_X(wx) ((wx) - cam_x)                   /* world -> screen */
#define W2S_Y(wy) ((wy) - cam_y)
```
Implementation notes:
- Lookup tables in RAM, built by `map_load`, one byte per character: `lut_tile[128]` (`128 + legend.tile`), `lut_attr[128]` (`pal & 0xE7`: palette, `MAP_FLIPX`/`MAP_FLIPY`, `MAP_OVER` priority), `lut_coll[128]`, `lut_tag[128]` (512 bytes in all). Unknown chars → blank, coll 0, tag 0.
- `map_coll_rect` / `map_tag_rect` (and `body_move`, `body_on_ground`, `body_touch_tags` through them) switch the map's bank once and walk the row strings: one cell costs ~1,900 cycles, each more cell in a row ~180. A rect that reaches left of, right of or above the map returns only `COLL_SOLID` (coll) or 0 (tag): those edges are walls, so a body is never partly there. Cells below the map are open (0) and the inside part is still read.
- `map_find` and `map_find_tag` share one row-by-row scan with one bank switch (~120 cycles per cell): cells are counted left to right, top to bottom.
- `map_char` = `rows[ty][tx] & 0x7F` (with bank switching when `bank != 0`).
- Maps smaller than the screen are drawn once and centered or top-left; clamp camera to `0..map_w_px-160` / `0..map_h_px-144` (0 if negative).
- Camera may move at most 8 px per frame per axis.
- **Streaming is deferred to VBlank.** `cam_follow` only gathers the new column/row into RAM and remembers the
  scroll; `map_flush` writes them to VRAM and sets SCX/SCY. `scene_update` calls `map_flush` first thing,
  right after `vsync()`, while VRAM is free: written while the screen is drawn, every VRAM byte waits for
  HBlank and one line cost ~39,000 cycles (a frame is 140,448). BG and sprites also change on the same frame.
  - `cam_set` draws and scrolls at once (scene start).
  - A second line on the same axis before a flush writes the first one immediately, so nothing is lost if
    `map_flush` is never called; it is only slower.
  - `map_set_tile` also patches a pending line, so a tile set right after `cam_follow` is not undone.
  - Blocking calls (`dialog_*`, `menu_run`, `input_wait_press`, `fade_*`) don't flush: call them before
    `cam_follow` in the update, or call `map_flush()` first. A game with its own `vsync()` loop that moves the
    camera calls `map_flush()` right after each `vsync()`.
- Internally map sizes and tile coordinates are `uint8_t` (maps are at most 200×200); the API keeps `uint16_t`.

**Legend: coll and tag.** The engine knows none of the pixel editor's tile flags (CLAUDE.md section 5). A legend entry `{ ch, tile, pal, coll, tag }` carries three bytes the AI fills in from them (graphics.md 6.5):

| Field | Values | Engine behavior |
|---|---|---|
| `pal` | BG palette 0–6 `\| MAP_FLIPX \| MAP_FLIPY \| MAP_OVER` | `MAP_OVER`: BG tile drawn over sprites (attribute bit 7) |
| `coll` | `COLL_SOLID` | Blocks `body_move` from every side; counts as ground |
| | `COLL_LEFT`, `COLL_RIGHT` | One-way: blocks bodies entering through that side (moving right / moving left); passable the other way (7.7) |
| | `COLL_TOP`, `COLL_BOTTOM` | One-way: blocks bodies falling onto it (jump-through platform, counts as ground) / moving up into it |
| `tag` | 8 bits, meaning defined by the game | Never read by the engine. Returned by `map_tag`, `map_tag_rect`, `body_touch_tags`; searched by `map_find_tag` |

Trailing fields can be left out: `{ '.', 0, 0 }` is coll 0, tag 0. Everything is `uint8_t`, so tests are single-byte ANDs. The game names its tag bits in `assets/assets.h` (`#define TAG_HAZARD 0x01`) and writes their meaning in `GAME.md` → *Tile flags*. Things found once on load (spawn points, arrivals) don't need a tag: find them by map character.

Scene links with LEAVE/ENTER (the game state remembers the arrival point):
```c
/* assets.h: LEAVE0 tiles got a tag bit */
#define TAG_DOOR 0x02

/* src/game/state.c */
uint8_t g_enter;                                   /* ENTERn the next scene uses */

/* level_update(): leaving */
if (body_touch_tags(&hero) & TAG_DOOR) { g_enter = 1; scene_goto(&scene_town, TRANS_FADE_BLACK); }   /* GAME.md: LEAVE0 -> town, ENTER1 */

/* town_enter(): arriving. GAME.md: ENTER0 = map char 'a', ENTER1 = 'b', SPAWN0 = 'P' */
uint16_t tx, ty;
if (!map_find(g_enter ? 'b' : 'a', 0, &tx, &ty)) map_find('P', 0, &tx, &ty);
hero.x = FIX(tx * 8); hero.y = FIX(ty * 8);
```

Streaming reference (the BG map is 32×32 and wraps; we redraw only the new column/row, in VBlank):
```c
static uint8_t drawn_tx, drawn_ty;             /* tile of the currently drawn top-left */
static uint8_t row_t[21], row_a[21], col_t[19], col_a[19];   /* pending row / column: tiles, attributes */
static uint8_t line_mx[2], line_my[2];          /* first map cell of line [0] row, [1] column */
static uint8_t line_pend, scx, scy;             /* bit 0 row, bit 1 column, bit 2 scroll */

/* VRAM copies: not set_bkg_tiles (~250 cycles per byte even in VBlank). Same wait as GBDK: none in VBlank.
   Two small functions so SDCC keeps the pointers in registers (~105 / ~130 cycles per byte). */
static void vram_row(uint8_t *d, const uint8_t *s, uint8_t n) {
    do { while (STAT_REG & STATF_BUSY); *d++ = *s++; } while (--n);
}
static void vram_col(uint8_t *d, const uint8_t *s, uint8_t n) {
    do { while (STAT_REG & STATF_BUSY); *d = *s++; d += 32; } while (--n);
}
static void line_put(uint8_t v, const uint8_t *src) {     /* line v, split where the 32x32 BG map wraps */
    uint8_t n = v ? 19 : 21, x = line_mx[v] & 31, y = line_my[v] & 31;
    uint8_t k = 32 - (v ? y : x);
    void (*copy)(uint8_t *, const uint8_t *, uint8_t) = v ? vram_col : vram_row;
    if (k > n) k = n;
    copy((uint8_t *)0x9800 + ((uint16_t)y << 5) + x, src, k);
    if (k < n) copy((uint8_t *)0x9800 + (v ? x : (uint16_t)y << 5), src + k, n - k);
}
static void line_write(uint8_t v) {
    VBK_REG = 1; line_put(v, v ? col_a : row_a);
    VBK_REG = 0; line_put(v, v ? col_t : row_t);
    line_pend &= ~(v + 1);
}
void map_flush(void) {
    if (line_pend & 4) move_bkg(scx, scy);
    if (line_pend & 1) line_write(0);
    if (line_pend & 2) line_write(1);
    line_pend = 0;
}
/* gathers row (v 0, 21 cells right) or column (v 1, 19 cells down): one bank switch, walks the row strings;
   cells outside the map are blank. A line already pending on this axis is written first. */
static void draw_line(uint8_t mx, uint8_t my, uint8_t v);
#define draw_col(mx, my) draw_line(mx, my, 1)
#define draw_row(mx, my) draw_line(mx, my, 0)

static void cam_apply(void) {          /* after cam_x/cam_y changed and were clamped */
    uint8_t tx = (uint16_t)cam_x >> 3, ty = (uint16_t)cam_y >> 3;
    while (drawn_tx < tx) { drawn_tx++; draw_col(drawn_tx + 20, drawn_ty); }
    while (drawn_tx > tx) { drawn_tx--; draw_col(drawn_tx,      drawn_ty); }
    while (drawn_ty < ty) { drawn_ty++; draw_row(drawn_tx, drawn_ty + 18); }
    while (drawn_ty > ty) { drawn_ty--; draw_row(drawn_tx, drawn_ty); }
    /* ...shake... */
    scx = (uint8_t)(cam_x + shake_dx); scy = (uint8_t)(cam_y + shake_dy);
    line_pend |= 4;
}
/* cam_set: set drawn_tx/ty = cam tile, draw rows ty..ty+18 fully (21 cells each), cam_apply(), map_flush()
   cam_reset: also clears line_pend. map_set_tile: also writes the cell into a pending line that covers it. */
```

### 7.7 collide

```c
typedef struct { int16_t x, y, vx, vy; uint8_t w, h; } body_t;   /* x,y,vx,vy fixed 12.4; w,h hitbox px */
#define HIT_LEFT 1
#define HIT_RIGHT 2
#define HIT_UP 4
#define HIT_DOWN 8
uint8_t rect_overlap(int16_t ax, int16_t ay, uint8_t aw, uint8_t ah,
                     int16_t bx, int16_t by, uint8_t bw, uint8_t bh);   /* pixels */
uint8_t body_overlap(const body_t *a, const body_t *b);
uint8_t body_move(body_t *b);           /* moves with tile collision, returns HIT_* bits */
uint8_t body_on_ground(const body_t *b);
uint8_t body_touch_tags(const body_t *b);   /* OR of the legend tags of all cells the hitbox covers */
```
Reference (speed must stay below 8 px/frame, i.e. |v| < FIX(8)). One helper moves one axis; one-way tiles (`COLL_LEFT/RIGHT/TOP/BOTTOM`) block only when the leading edge crosses into their column or row in this move, so a body already inside one is never snapped:
```c
/* any cell with a COLL_* bit of mask on an edge: vertical edge at x = e from y = o, or horizontal at y = e from x = o */
static uint8_t edge_hit(uint8_t vert, int16_t e, int16_t o, uint8_t len, uint8_t mask) {
    int16_t end = o + len - 1;
    return (vert ? map_coll_rect(e, o, e, end) : map_coll_rect(o, e, end, e)) & mask;
}

/* a one-way tile blocks only when the moving edge crosses into its column/row (a ^ b differ above bit 2) */
#define CROSSED(a, b) ((((a) ^ (b)) & ~7) != 0)

/* moves *p (fixed) by v along one axis (vert: x axis, the leading edge is vertical); size = hitbox size on
   that axis, o/len = hitbox start/size on the other one. Returns 1 when blocked, with *p snapped to the tile. */
static uint8_t axis_move(int16_t *p, int16_t v, uint8_t size, uint8_t vert, int16_t o, uint8_t len) {
    int16_t old = UNFIX(*p), q, e;
    uint8_t mask = COLL_SOLID;
    *p += v;
    q = UNFIX(*p);
    if (v > 0) {
        e = q + size - 1;
        if (CROSSED(old + size - 1, e)) mask |= vert ? COLL_LEFT : COLL_TOP;      /* entered from left / above */
        if (edge_hit(vert, e, o, len, mask)) { *p = FIX((e & ~7) - size); return 1; }
    } else if (v < 0) {
        if (CROSSED(old, q)) mask |= vert ? COLL_RIGHT : COLL_BOTTOM;              /* entered from right / below */
        if (edge_hit(vert, q, o, len, mask)) { *p = FIX((q & ~7) + 8); return 1; }
    }
    return 0;
}

uint8_t body_move(body_t *b) {
    uint8_t hit = 0;
    if (axis_move(&b->x, b->vx, b->w, 1, UNFIX(b->y), b->h)) { hit = b->vx > 0 ? HIT_RIGHT : HIT_LEFT; b->vx = 0; }
    if (axis_move(&b->y, b->vy, b->h, 0, UNFIX(b->x), b->w)) { hit |= b->vy > 0 ? HIT_DOWN : HIT_UP; b->vy = 0; }
    return hit;
}

uint8_t body_on_ground(const body_t *b) {
    int16_t x = UNFIX(b->x), y = UNFIX(b->y) + b->h;
    return (map_coll_rect(x, y, x + b->w - 1, y) & (COLL_SOLID | COLL_TOP)) != 0;
}

uint8_t body_touch_tags(const body_t *b) {
    int16_t x = UNFIX(b->x), y = UNFIX(b->y);
    return map_tag_rect(x, y, x + b->w - 1, y + b->h - 1);
}
```
Platformer: `vy += GRAVITY` (e.g. 5), clamp `vy` to `FIX(4)`, jump `vy = -FIX(3)`, variable jump: if A released while `vy < 0`, `vy >>= 1`. Top-down: no gravity, set `vx/vy` from the d-pad.

### 7.8 text, dialogs, menus

```c
#define FONT_TILE(c) ((uint8_t)(((c) >= 32 && (c) < 128) ? 128 + (c) - 32 : 128))
#define TILE_BLANK 128
#define ATTR_BLANK 0x0F                    /* bank 1 + palette 7 */
#define BOX_TILE0  224                     /* TL, T, TR, L, FILL, R, BL, B, BR, NEXT (bank 1) */
#define BOX_TILE(n) ((uint8_t)(BOX_TILE0 + (n)))
extern const palette_color_t pal_ui_default[4];   /* engine default UI colors (restore after text_set_colors) */
void text_init(void);                      /* expand 1bpp font to 2bpp glyph by glyph (16-byte buffer),
                                              VBK_REG = 1, set_bkg_data(128 + i, 1, buf); box tiles at 224 */
void text_set_colors(const palette_color_t *c4);   /* BG palette 7 */
void text_print(uint8_t x, uint8_t y, const char *s);      /* BG layer, tile coords relative to camera
                                                              top-left: x + (cam_x>>3), wrapped &31 */
void text_print_win(uint8_t x, uint8_t y, const char *s);  /* window layer */
void text_print_num(uint8_t x, uint8_t y, uint16_t n, uint8_t digits);       /* BG, zero padded */
void text_print_num_win(uint8_t x, uint8_t y, uint16_t n, uint8_t digits);   /* window, zero padded */
void text_clear(uint8_t x, uint8_t y, uint8_t w, uint8_t h);
void box_draw_win(uint8_t x, uint8_t y, uint8_t w, uint8_t h);           /* bordered box on window */

void dialog_show(const char *text);        /* BLOCKING */
uint8_t dialog_choice(const char *prompt, const char * const *options, uint8_t count);  /* BLOCKING, returns index */
uint8_t menu_run(uint8_t x, uint8_t y, const char * const *options, uint8_t count);    /* BLOCKING, on BG, arrow cursor */
```
Writing a character: write tile `FONT_TILE(c)` with `VBK_REG = 0` and attribute `ATTR_BLANK` with `VBK_REG = 1`, then leave `VBK_REG = 0`.

`dialog_show` behavior: window box 20×5 tiles at the bottom (`move_win(7, 104)`, `SHOW_WIN`), 3 lines × 18 chars; typewriter 1 char every 2 frames (every frame while A held); automatic word wrap (a word longer than 18 chars is cut at the row end); `\n` = new line; `\f` = new page; when a page is full or text ends, blink the NEXT arrow and wait for `A`; plays `sfx_menu` per page; `HIDE_WIN` at the end. Its loop calls `vsync(); input_update();` itself (audio keeps playing via interrupt). Sprites stay frozen as last drawn.

HUD: the window always covers everything from its top line down to the bottom of the screen, so it can't be a top bar. Put the HUD at the bottom (`move_win(7, 136)` = 1 row), or draw a small HUD with sprites. While a dialog is open, the dialog takes over the window.

### 7.9 scene manager

```c
typedef struct { void (*enter)(void); void (*update)(void); void (*leave)(void); } scene_t;  /* leave may be 0 */
#define TRANS_NONE 0
#define TRANS_FADE_BLACK 1
#define TRANS_FADE_WHITE 2
void scene_start(const scene_t *first);
void scene_goto(const scene_t *next, uint8_t transition);   /* request; performed at end of this frame */
void scene_update(void);
void scene_reset_screen(void);   /* hide sprites + window, fill BG map with TILE_BLANK/ATTR_BLANK
                                    (fill_bkg_rect on VRAM bank 0 and 1), move_bkg(0,0) */
```
Reference:
```c
static const scene_t *cur, *pending;
static uint8_t pending_trans;

static void run_frame(void) { spr_begin(); cur->update(); spr_end(); }

void scene_start(const scene_t *first) {
    cur = first; cur->enter(); run_frame(); map_flush(); fade_in(4, 0);
}
void scene_update(void) {
    map_flush();                /* still in VBlank: VRAM writes don't wait (7.6) */
    run_frame();
    if (!pending) return;
    uint8_t white = (pending_trans == TRANS_FADE_WHITE);
    if (pending_trans != TRANS_NONE) fade_out(4, white);
    if (cur->leave) cur->leave();
    scene_reset_screen(); gfx_reset(); tween_clear(); particles_clear(); cam_reset();
    cur = pending; pending = 0;
    cur->enter();
    run_frame();
    map_flush();
    if (pending_trans != TRANS_NONE) fade_in(4, white); else fade_set_level(0);
}
```

### 7.10 fade

The engine keeps a RAM copy of all 16 palettes (`pal_ram[64]`: 0–31 BG, 32–63 OBJ) and a fade level 0 (normal) … 8 (fully black/white). `gfx_set_*_palette` writes to RAM and then applies the current level, so palettes loaded while faded out stay invisible.

```c
extern palette_color_t pal_ram[64];                    /* 0-31 BG, 32-63 OBJ */
void fade_init(void);                                  /* all black, level 8 */
void fade_out(uint8_t frames_per_step, uint8_t to_white);   /* BLOCKING, 8 steps */
void fade_in(uint8_t frames_per_step, uint8_t from_white);  /* BLOCKING */
void fade_set_level(uint8_t level);
void fade_apply(void);
```
Reference:
```c
static uint8_t lut[32];              /* channel value 0-31 -> faded value at the current level */

/* black: v - (v*level >> 3); white: v + ((31-v)*level >> 3). Built with adds only:
   per-color multiplies made one call longer than a frame, so every fade step lost a VBlank */
void fade_apply(void) {
    static palette_color_t tmp[64];
    uint8_t i, v, acc = 0;
    palette_color_t c;
    if (fade_white) { v = 31; do { lut[v] = v + (acc >> 3); acc += fade_level; } while (v--); }
    else            { for (v = 0; v < 32; v++) { lut[v] = v - (acc >> 3); acc += fade_level; } }
    for (i = 0; i < 64; i++) {
        c = pal_ram[i];
        tmp[i] = RGB(lut[c & 31], lut[(c >> 5) & 31], lut[(c >> 10) & 31]);
    }
    set_bkg_palette(0, 8, tmp);
    set_sprite_palette(0, 8, tmp + 32);
}
void fade_out(uint8_t fps, uint8_t to_white) {
    uint8_t s, f;
    fade_white = to_white;
    for (s = 1; s <= 8; s++) { fade_level = s; vsync(); fade_apply(); for (f = 1; f < fps; f++) vsync(); }
}
/* fade_in: same with s = 7 down to 0 */
```

### 7.11 tween

```c
#define EASE_LINEAR 0
#define EASE_IN 1
#define EASE_OUT 2
#define EASE_INOUT 3
uint8_t tween_start(int16_t *target, int16_t to, uint8_t frames, uint8_t ease);  /* from = *target now */
void tween_update(void);            /* once per frame */
uint8_t tween_busy(const int16_t *target);
void tween_clear(void);             /* pool of 8 */
```
Easing tables (17 entries, progress 0..16 → 0..256), interpolate between entries:
```c
static const uint16_t ease_tbl[4][17] = {
  {0,16,32,48,64,80,96,112,128,144,160,176,192,208,224,240,256},
  {0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225,256},
  {0,31,60,87,112,135,156,175,192,207,220,231,240,247,252,255,256},
  {0,2,8,18,32,50,72,98,128,158,184,206,224,238,248,254,256},
};
/* p = (t << 8) / dur (0..256); i = p >> 4; e = tbl[i] + (((tbl[i+1]-tbl[i]) * (p & 15)) >> 4) (i < 16);
   *target = from + (int16_t)(((int32_t)(to - from) * e) >> 8); on the last frame set *target = to exactly */
```
Use for menus sliding in, cameras, UI bounce, moving platforms on rails, title logos.

### 7.12 particles

```c
typedef struct {
    const sprite_t *spr;   /* 1x1 sprite; frames play across the lifetime */
    uint8_t speed;         /* max initial speed, 1/16 px per frame (24 = 1.5 px) */
    int8_t  up;            /* added to initial vy (negative = upward burst) */
    int8_t  gravity;       /* added to vy every frame */
    uint8_t life;          /* frames */
} particle_style_t;
void particles_emit(int16_t wx, int16_t wy, uint8_t count, const particle_style_t *st);  /* world px */
void particles_update(void);   /* move + draw (call inside update, after the important sprites) */
void particles_clear(void);    /* pool of 12; emitting when full recycles the oldest */
```
Random velocity: a random byte scaled to `2 * speed + 1` values, `((uint16_t)(uint8_t)rand() * (2 * speed + 1) >> 8) - speed`
(a multiply: `%` is a slow library call). The frame step `life / frames` is computed once per `particles_emit`.
Particles are drawn with `spr_put` (1x1: tile `base + frame`). Keep bursts ≤ 8 particles because of the 10-per-line limit.
