/* src/engine/collide.c: rect/body overlap, body_move against tiles (COLL_*), ground and tag queries */
#pragma bank 255
#include "unit.h"

extern const uint8_t font_main[];   /* used as arbitrary tile data */

static const palette_color_t pal0[4] = { RGB(0,0,0), RGB(10,10,10), RGB(20,20,20), RGB(31,31,31) };
static const palette_color_t * const pals[1] = { pal0 };
static const tileset_def_t ts = { font_main, 5, pals, 1 };
static const map_legend_t legend[] = {
    { '.', 0, 0 },
    { '#', 1, 0, COLL_SOLID },
    { '=', 2, 0, COLL_TOP },              /* jump-through platform */
    { '>', 2, 0, COLL_RIGHT },            /* passable moving right only */
    { '<', 2, 0, COLL_LEFT },             /* passable moving left only */
    { 'v', 2, 0, COLL_BOTTOM },           /* passable moving down only */
    { '^', 3, 0, 0, 0x01 },               /* tags: meanings are the game's */
    { 'D', 4, 0, 0, 0x02 },
    { 'L', 4, 0, 0, 0x04 },
    { 'N', 4, 0, 0, 0x80 | 0x10 },
    { 0 },
};
/* 24 x 18 tiles = 192 x 144 px
   row 2: one-way left '<' x 64..71, one-way right '>' x 160..167 | row 7 cols 18-19: one-way down x 144..159
   row 5: ceiling block x 16..47 | col 12 rows 10-15: wall x 96..103 | row 10 cols 16-20: one-way up x 128..167
   row 15: tag 0x01 x 16..31, 0x02 x 40..47, 0x04 x 48..55, 0x90 x 56..63 | rows 16-17: floor from y 128 */
static const char * const rows[18] = {
    "........................",
    "........................",
    "........<...........>...",
    "........................",
    "........................",
    "..####..................",
    "........................",
    "..................vv....",
    "........................",
    "........................",
    "............#...=====...",
    "............#...........",
    "............#...........",
    "............#...........",
    "............#...........",
    "..^^.DLN....#...........",
    "########################",
    "########################",
};
static const map_def_t room = { 24, 18, rows, legend, &ts };

static body_t b, o;

static void body_at(body_t *p, int16_t x, int16_t y, uint8_t w, uint8_t h) {
    p->x = FIX(x); p->y = FIX(y); p->vx = p->vy = 0; p->w = w; p->h = h;
}

void unit_setup(void) BANKED {
    unit_reset_engine();
    map_load(&room, 0);
}

TEST(rect_overlap_cases) {
    ASSERT_EQ(rect_overlap(0, 0, 8, 8, 4, 4, 8, 8), 1);
    ASSERT_EQ(rect_overlap(0, 0, 8, 8, 8, 0, 8, 8), 0);      /* touching edges */
    ASSERT_EQ(rect_overlap(0, 0, 8, 8, 0, 8, 8, 8), 0);
    ASSERT_EQ(rect_overlap(8, 0, 8, 8, 0, 0, 8, 8), 0);
    ASSERT_EQ(rect_overlap(0, 0, 16, 16, 4, 4, 2, 2), 1);    /* contained */
    ASSERT_EQ(rect_overlap(4, 4, 2, 2, 0, 0, 16, 16), 1);
    ASSERT_EQ(rect_overlap(-10, -10, 12, 12, 0, 0, 4, 4), 1); /* negative coords */
    ASSERT_EQ(rect_overlap(-10, -10, 10, 10, 0, 0, 4, 4), 0);
    ASSERT_EQ(rect_overlap(0, 0, 8, 8, 100, 100, 8, 8), 0);
}

TEST(body_overlap_uses_pixels) {
    body_at(&b, 10, 10, 8, 8);
    body_at(&o, 17, 10, 8, 8);
    ASSERT_EQ(body_overlap(&b, &o), 1);
    o.x = FIX(18);
    ASSERT_EQ(body_overlap(&b, &o), 0);
    o.x = FIX(17) + 15;                    /* 17.94 px truncates to 17 */
    ASSERT_EQ(body_overlap(&b, &o), 1);
    o.y = FIX(18);                         /* x overlaps, y apart */
    ASSERT_EQ(body_overlap(&b, &o), 0);
    o.y = FIX(3);
    ASSERT_EQ(body_overlap(&b, &o), 1);
    o.y = FIX(-8) + 1;                     /* negative: -7.94 px shifts to -8, touching edge */
    o.h = 18;
    ASSERT_EQ(body_overlap(&b, &o), 0);
    o.h = 19;
    ASSERT_EQ(body_overlap(&b, &o), 1);
}

TEST(move_in_open_air) {
    body_at(&b, 40, 56, 8, 8);
    b.vx = FIX(2); b.vy = FIX(1);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.x, FIX(42));
    ASSERT_EQ(b.y, FIX(57));
    ASSERT_EQ(b.vx, FIX(2));
    ASSERT_EQ(b.vy, FIX(1));
}

TEST(move_keeps_subpixels) {
    body_at(&b, 40, 56, 8, 8);
    b.vx = 5; b.vy = -3;
    body_move(&b);
    ASSERT_EQ(b.x, FIX(40) + 5);
    ASSERT_EQ(b.y, FIX(56) - 3);
}

TEST(land_on_floor) {
    body_at(&b, 64, 118, 8, 8);
    b.vy = FIX(8);
    ASSERT_EQ(body_move(&b), HIT_DOWN);
    ASSERT_EQ(b.y, FIX(120));              /* bottom row 127, floor starts at 128 */
    ASSERT_EQ(b.vy, 0);
}

TEST(hit_wall_moving_right) {
    body_at(&b, 80, 100, 8, 8);
    b.vx = FIX(12);
    ASSERT_EQ(body_move(&b), HIT_RIGHT);
    ASSERT_EQ(b.x, FIX(88));
    ASSERT_EQ(b.vx, 0);
}

TEST(hit_wall_moving_left) {
    body_at(&b, 108, 100, 8, 8);
    b.vx = -FIX(6);
    ASSERT_EQ(body_move(&b), HIT_LEFT);
    ASSERT_EQ(b.x, FIX(104));
    ASSERT_EQ(b.vx, 0);
}

TEST(hit_ceiling_moving_up) {
    body_at(&b, 24, 52, 8, 8);
    b.vy = -FIX(6);
    ASSERT_EQ(body_move(&b), HIT_UP);
    ASSERT_EQ(b.y, FIX(48));
    ASSERT_EQ(b.vy, 0);
}

TEST(hit_wall_and_floor_same_move) {
    body_at(&b, 84, 118, 8, 8);
    b.vx = FIX(8); b.vy = FIX(8);
    ASSERT_EQ(body_move(&b), HIT_RIGHT | HIT_DOWN);
    ASSERT_EQ(b.x, FIX(88));
    ASSERT_EQ(b.y, FIX(120));
}

TEST(world_edges_are_solid) {
    body_at(&b, 1, 56, 8, 8);
    b.vx = -FIX(3);
    ASSERT_EQ(body_move(&b), HIT_LEFT);
    ASSERT_EQ(b.x, 0);

    body_at(&b, 180, 56, 8, 8);            /* map is 192 px wide */
    b.vx = FIX(8);
    ASSERT_EQ(body_move(&b), HIT_RIGHT);
    ASSERT_EQ(b.x, FIX(184));

    body_at(&b, 40, 2, 8, 8);
    b.vy = -FIX(4);
    ASSERT_EQ(body_move(&b), HIT_UP);
    ASSERT_EQ(b.y, 0);
}

TEST(below_map_is_open) {
    body_at(&b, 40, 146, 8, 8);
    b.vy = FIX(4);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.y, FIX(150));
}

TEST(oneway_up_lands_from_above) {
    body_at(&b, 136, 64, 8, 8);
    b.vy = FIX(12);
    ASSERT_EQ(body_move(&b), HIT_DOWN);
    ASSERT_EQ(b.y, FIX(72));
}

TEST(oneway_up_passes_from_below) {
    body_at(&b, 136, 90, 8, 8);
    b.vy = -FIX(6);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.y, FIX(84));
}

TEST(oneway_up_ignored_when_already_inside) {
    body_at(&b, 136, 76, 8, 8);            /* bottom already in the platform row */
    b.vy = FIX(2);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.y, FIX(78));
}

TEST(oneway_up_passes_sideways) {
    body_at(&b, 120, 80, 8, 8);
    b.vx = FIX(8);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.x, FIX(128));
}

TEST(oneway_right_blocks_moving_left) {
    body_at(&b, 170, 16, 8, 8);
    b.vx = -FIX(4);
    ASSERT_EQ(body_move(&b), HIT_LEFT);
    ASSERT_EQ(b.x, FIX(168));
    ASSERT_EQ(b.vx, 0);
}

TEST(oneway_right_passes_moving_right) {
    body_at(&b, 150, 16, 8, 8);
    b.vx = FIX(8);
    ASSERT_EQ(body_move(&b), 0);           /* right edge enters the column */
    ASSERT_EQ(b.x, FIX(158));
    b.vx = FIX(8);
    ASSERT_EQ(body_move(&b), 0);           /* and leaves it on the other side */
    ASSERT_EQ(b.x, FIX(166));
}

TEST(oneway_right_ignored_when_already_inside) {
    body_at(&b, 166, 16, 8, 8);            /* left edge already in the column */
    b.vx = -FIX(2);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.x, FIX(164));
}

TEST(oneway_right_passes_vertically) {
    body_at(&b, 160, 6, 8, 8);
    b.vy = FIX(6);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.y, FIX(12));
}

TEST(oneway_left_blocks_moving_right) {
    body_at(&b, 54, 16, 8, 8);
    b.vx = FIX(4);
    ASSERT_EQ(body_move(&b), HIT_RIGHT);
    ASSERT_EQ(b.x, FIX(56));
    ASSERT_EQ(b.vx, 0);
}

TEST(oneway_left_passes_moving_left) {
    body_at(&b, 74, 16, 8, 8);
    b.vx = -FIX(6);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.x, FIX(68));
}

TEST(oneway_down_blocks_moving_up) {
    body_at(&b, 148, 66, 8, 8);
    b.vy = -FIX(4);
    ASSERT_EQ(body_move(&b), HIT_UP);
    ASSERT_EQ(b.y, FIX(64));
    ASSERT_EQ(b.vy, 0);
}

TEST(oneway_down_passes_moving_down) {
    body_at(&b, 148, 46, 8, 8);
    b.vy = FIX(6);
    ASSERT_EQ(body_move(&b), 0);
    ASSERT_EQ(b.y, FIX(52));
    ASSERT_EQ(body_on_ground(&b), 0);      /* only one-way up counts as ground */
}

TEST(wide_body_checks_every_8_px) {
    body_at(&b, 90, 64, 20, 8);            /* covers x 90..109, the wall column is 96..103 */
    b.vy = FIX(12);
    ASSERT_EQ(body_move(&b), HIT_DOWN);
    ASSERT_EQ(b.y, FIX(72));
}

TEST(tall_body_checks_every_8_px) {
    body_at(&b, 80, 88, 8, 24);            /* rows 11..13 against the wall */
    b.vx = FIX(10);
    ASSERT_EQ(body_move(&b), HIT_RIGHT);
    ASSERT_EQ(b.x, FIX(88));
}

TEST(on_ground_queries) {
    body_at(&b, 64, 120, 8, 8);
    ASSERT_EQ(body_on_ground(&b), 1);
    b.y = FIX(119);
    ASSERT_EQ(body_on_ground(&b), 0);
    body_at(&b, 136, 72, 8, 8);            /* standing on the one-way platform */
    ASSERT_EQ(body_on_ground(&b), 1);
    body_at(&b, 64, 56, 8, 8);            /* open air */
    ASSERT_EQ(body_on_ground(&b), 0);
}

TEST(touch_tags_or_all_covered_tiles) {
    body_at(&b, 24, 116, 20, 8);           /* cols 3..5, rows 14..15 */
    ASSERT_EQ(body_touch_tags(&b), 0x01 | 0x02);
    body_at(&b, 44, 120, 16, 8);           /* cols 5..7 */
    ASSERT_EQ(body_touch_tags(&b), 0x02 | 0x04 | 0x90);
    body_at(&b, 64, 56, 8, 8);            /* open air */
    ASSERT_EQ(body_touch_tags(&b), 0);
    body_at(&b, 92, 124, 8, 8);            /* wall + floor: coll only, no tags */
    ASSERT_EQ(body_touch_tags(&b), 0);
    body_at(&b, 16, 120, 1, 1);            /* single pixel on the first tagged cell */
    ASSERT_EQ(body_touch_tags(&b), 0x01);
    body_at(&b, 31, 120, 10, 8);           /* x 31..40: last pixel of '^' and first of 'D', nothing between */
    ASSERT_EQ(body_touch_tags(&b), 0x01 | 0x02);
}

TEST(touch_tags_outside_map_are_0) {
    body_at(&b, -12, 116, 8, 8);           /* wholly left of the map */
    ASSERT_EQ(body_touch_tags(&b), 0);
    body_at(&b, -4, 116, 21, 8);           /* partly left (x -4..16): the left edge is a wall, no tags */
    ASSERT_EQ(body_touch_tags(&b), 0);
    body_at(&b, 16, 120, 8, 40);           /* y 120..159: the tagged row 15, the floor, then below the map */
    ASSERT_EQ(body_touch_tags(&b), 0x01);
    body_at(&b, 40, 150, 8, 8);            /* below */
    ASSERT_EQ(body_touch_tags(&b), 0);
}

TEST(on_ground_at_map_edges) {
    body_at(&b, -4, 120, 8, 8);            /* half left of the map, over the floor */
    ASSERT_EQ(body_on_ground(&b), 1);
    body_at(&b, 40, 144, 8, 8);            /* below the map: nothing to stand on */
    ASSERT_EQ(body_on_ground(&b), 0);
    body_at(&b, 90, 56, 20, 8);            /* wide body over the wall top (x 96..103, y 80) */
    b.y = FIX(72);
    ASSERT_EQ(body_on_ground(&b), 1);
}

void unit_tests(void) BANKED {
    RUN(rect_overlap_cases);
    RUN(body_overlap_uses_pixels);
    RUN(move_in_open_air);
    RUN(move_keeps_subpixels);
    RUN(land_on_floor);
    RUN(hit_wall_moving_right);
    RUN(hit_wall_moving_left);
    RUN(hit_ceiling_moving_up);
    RUN(hit_wall_and_floor_same_move);
    RUN(world_edges_are_solid);
    RUN(below_map_is_open);
    RUN(oneway_up_lands_from_above);
    RUN(oneway_up_passes_from_below);
    RUN(oneway_up_ignored_when_already_inside);
    RUN(oneway_up_passes_sideways);
    RUN(oneway_right_blocks_moving_left);
    RUN(oneway_right_passes_moving_right);
    RUN(oneway_right_ignored_when_already_inside);
    RUN(oneway_right_passes_vertically);
    RUN(oneway_left_blocks_moving_right);
    RUN(oneway_left_passes_moving_left);
    RUN(oneway_down_blocks_moving_up);
    RUN(oneway_down_passes_moving_down);
    RUN(wide_body_checks_every_8_px);
    RUN(tall_body_checks_every_8_px);
    RUN(on_ground_queries);
    RUN(touch_tags_or_all_covered_tiles);
    RUN(touch_tags_outside_map_are_0);
    RUN(on_ground_at_map_edges);
}
