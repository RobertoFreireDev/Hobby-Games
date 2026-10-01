#ifndef MAP_H
#define MAP_H
#include "core.h"

typedef struct {
    const uint8_t *tiles; uint8_t count;                     /* count <= 128 */
    const palette_color_t * const *pals; uint8_t pal_count;  /* BG slots 0..pal_count-1 (max 7) */
} tileset_def_t;

/* One legend entry per map character; the list ends with ch 0. The engine knows none of the pixel editor's tile
   flags: the AI turns the ones a game needs into pal (MAP_OVER), coll and tag when it writes the legend. */
typedef struct {
    char ch;
    uint8_t tile;    /* tileset index */
    uint8_t pal;     /* BG palette 0-6, optionally | MAP_FLIPX | MAP_FLIPY | MAP_OVER */
    uint8_t coll;    /* COLL_* bits: how body_move treats the cell (0 = passable) */
    uint8_t tag;     /* 8 game-defined bits, never read by the engine (body_touch_tags, map_find_tag) */
} map_legend_t;
typedef struct {
    uint8_t w, h;                      /* in tiles, 20..200 each */
    const char * const *rows;          /* h strings, each exactly w chars */
    const map_legend_t *legend;
    const tileset_def_t *tileset;
} map_def_t;

/* legend pal: visual only */
#define MAP_FLIPX 0x20
#define MAP_FLIPY 0x40
#define MAP_OVER  0x80   /* BG tile drawn over sprites (BG priority) */
/* legend coll */
#define COLL_SOLID  0x01   /* blocks from every side */
#define COLL_LEFT   0x02   /* one-way: blocks bodies entering through its left side (moving right) */
#define COLL_RIGHT  0x04   /* one-way: blocks bodies entering through its right side (moving left) */
#define COLL_TOP    0x08   /* one-way: blocks bodies falling onto it: jump-through platform, counts as ground */
#define COLL_BOTTOM 0x10   /* one-way: blocks bodies moving up into it */

void    map_load(const map_def_t *m, uint8_t bank);
char    map_char(uint16_t tx, uint16_t ty);
uint8_t map_coll(uint16_t tx, uint16_t ty);        /* COLL_* bits; outside left/right/top = COLL_SOLID, below = 0 */
uint8_t map_coll_px(int16_t px, int16_t py);       /* same, world pixel coords */
uint8_t map_coll_rect(int16_t x0, int16_t y0, int16_t x1, int16_t y1);  /* OR of every cell the pixel rect covers */
uint8_t map_tag(uint16_t tx, uint16_t ty);         /* legend tag; 0 outside the map */
uint8_t map_tag_rect(int16_t x0, int16_t y0, int16_t x1, int16_t y1);   /* OR of every cell the pixel rect covers */
uint8_t map_find(char ch, uint8_t n, uint16_t *tx, uint16_t *ty);  /* n-th occurrence, returns 0 if none */
uint8_t map_find_tag(uint8_t mask, uint8_t n, uint16_t *tx, uint16_t *ty);  /* n-th cell with any tag bit of mask */
void    map_set_tile(uint16_t tx, uint16_t ty, char ch);  /* changes the VRAM tile only (visual) */
extern uint16_t map_w_px, map_h_px;

extern int16_t cam_x, cam_y;                       /* world pixel of screen top-left */
void cam_set(int16_t x, int16_t y);                /* clamp + redraw full screen (use at scene start) */
void cam_follow(int16_t wx, int16_t wy);           /* center on point with small dead zone, clamp, stream */
void map_flush(void);    /* writes what cam_follow streamed + the scroll; scene_update calls it after vsync */
void cam_shake(uint8_t frames, uint8_t strength);  /* applied by cam_follow */
void cam_reset(void);                              /* called by the scene manager */
#define W2S_X(wx) ((wx) - cam_x)                   /* world -> screen */
#define W2S_Y(wy) ((wy) - cam_y)
#endif
