#include "engine/engine.h"

static uint8_t span_overlap(int16_t a, uint8_t al, int16_t b, uint8_t bl) { return a < b + bl && b < a + al; }

uint8_t rect_overlap(int16_t ax, int16_t ay, uint8_t aw, uint8_t ah,
                     int16_t bx, int16_t by, uint8_t bw, uint8_t bh) {
    return span_overlap(ax, aw, bx, bw) && span_overlap(ay, ah, by, bh);
}

uint8_t body_overlap(const body_t *a, const body_t *b) {    /* not through rect_overlap: 8 arguments cost more */
    return span_overlap(UNFIX(a->x), a->w, UNFIX(b->x), b->w) && span_overlap(UNFIX(a->y), a->h, UNFIX(b->y), b->h);
}

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
