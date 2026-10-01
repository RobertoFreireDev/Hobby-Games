#pragma bank 255
#include "engine/engine.h"
/* Scroll stress map: 200x64 cells (the engine maximum width), ~13 KB in its own bank with its tileset.
   Region colors change every 20 columns / 16 rows, diagonal block stripes cross every cell row and a
   diamond marks every 10th column of every 8th row, so a cell streamed to the wrong place shows at once.
   Rows follow one rule: region = (x/20 + y/16) % 7; diamond if x%10==0 && y%8==0;
   block if (x+y)%9==0 || (x-y+910)%13==0; floor otherwise. */
BANKREF(map_scroll)

static const palette_color_t pal_red[4] = { RGB8(248,216,208), RGB8(232,160,144), RGB8(200,72,64), RGB8(88,24,24) };
static const palette_color_t pal_orange[4] = { RGB8(248,232,200), RGB8(240,184,120), RGB8(216,120,40), RGB8(96,48,16) };
static const palette_color_t pal_yellow[4] = { RGB8(248,248,200), RGB8(232,224,128), RGB8(192,168,40), RGB8(88,72,16) };
static const palette_color_t pal_green[4] = { RGB8(216,248,208), RGB8(152,216,136), RGB8(64,160,72), RGB8(24,72,32) };
static const palette_color_t pal_cyan[4] = { RGB8(208,248,248), RGB8(128,208,216), RGB8(40,144,168), RGB8(16,64,80) };
static const palette_color_t pal_blue[4] = { RGB8(208,224,248), RGB8(136,160,232), RGB8(64,88,200), RGB8(24,32,96) };
static const palette_color_t pal_purple[4] = { RGB8(232,216,248), RGB8(184,152,232), RGB8(128,72,192), RGB8(56,24,88) };

static const uint8_t ts_scroll_tiles[] = {
    /* 0: floor (grid lines right/bottom) */
    PX(0,0,0,0,0,0,0,1), PX(0,0,0,0,0,0,0,1), PX(0,0,0,0,0,0,0,1), PX(0,0,0,0,0,0,0,1),
    PX(0,0,0,0,0,0,0,1), PX(0,0,0,0,0,0,0,1), PX(0,0,0,0,0,0,0,1), PX(1,1,1,1,1,1,1,1),
    /* 1: block (bevel) */
    PX(1,1,1,1,1,1,1,2), PX(1,2,2,2,2,2,2,3), PX(1,2,2,2,2,2,2,3), PX(1,2,2,2,2,2,2,3),
    PX(1,2,2,2,2,2,2,3), PX(1,2,2,2,2,2,2,3), PX(1,2,2,2,2,2,2,3), PX(2,3,3,3,3,3,3,3),
    /* 2: marker diamond (every 10 x 8 cells) */
    PX(0,0,0,3,3,0,0,0), PX(0,0,3,2,2,3,0,0), PX(0,3,2,2,2,2,3,0), PX(3,2,2,1,1,2,2,3),
    PX(3,2,2,1,1,2,2,3), PX(0,3,2,2,2,2,3,0), PX(0,0,3,2,2,3,0,0), PX(0,0,0,3,3,0,0,0),
};
static const palette_color_t * const ts_scroll_pals[] = { pal_red, pal_orange, pal_yellow, pal_green, pal_cyan, pal_blue, pal_purple };
static const tileset_def_t ts_scroll = { ts_scroll_tiles, 3, ts_scroll_pals, 7 };

static const map_legend_t legend[] = {
    { 'a', 0, 0, 0 }, { 'A', 1, 0, COLL_SOLID }, { '1', 2, 0, 0 },   /* red */
    { 'b', 0, 1, 0 }, { 'B', 1, 1, COLL_SOLID }, { '2', 2, 1, 0 },   /* orange */
    { 'c', 0, 2, 0 }, { 'C', 1, 2, COLL_SOLID }, { '3', 2, 2, 0 },   /* yellow */
    { 'd', 0, 3, 0 }, { 'D', 1, 3, COLL_SOLID }, { '4', 2, 3, 0 },   /* green */
    { 'e', 0, 4, 0 }, { 'E', 1, 4, COLL_SOLID }, { '5', 2, 4, 0 },   /* cyan */
    { 'f', 0, 5, 0 }, { 'F', 1, 5, COLL_SOLID }, { '6', 2, 5, 0 },   /* blue */
    { 'g', 0, 6, 0 }, { 'G', 1, 6, COLL_SOLID }, { '7', 2, 6, 0 },   /* purple */
    { 0 }
};

static const char * const rows[] = {
/* 0*/ "1aaaaaaaaA1aaAaaaaAa2bbbbbBBbb2bbbbbBbbB3ccccCcccc3cCcCccccc4ddDdDdddd4dDdddddDd5Eeeeeeeee5EeeeeeeeE6fffFfffFf6ffffffFff7gggggGggg7ggggGgggg1aaAAaaaaa1aaAaaAaaa2bBbbbbbbB2Bbbbbbbbb3cCccccccC3ccccCccCc",
/* 1*/ "aAaaaaaaAaaaaaAaaAaabbbbbbBBbbbbbbbBbbbbCcccCccccccccCccccccddDdddDddddDdddddddDEeeeeeeeeEeeEeeeeeEefffffFfFffffffffFfFfgggggGgggggGggGgggggaaaAAaaaaaaaAaaaaAaabBbbbbbbbbBbbbbbbbbBcccCccccCcccccccCCcc",
/* 2*/ "aaAaaaaAaaaaaaaAAaaabbbbbBbbBbbbbbBbbbbbcCcCccccccccCcCcccccdDdddddDddDddddddddDEeeeeeeeEeeeeEeeeEeeffffffFffffffffFfffFggggGgggggggGGggggggaaAaaAaaaaaAaaaaaaAaBbbbbbbbbBbBbbbbbbBbccccCccCccccccccCCcc",
/* 3*/ "aaaAaaAaaaaaaaaAAaaabbbbBbbbbBbbbBbbbbbbccCccccccccCcccCccccDdddddddDDddddddddDdeEeeeeeEeeeeeeEeEeeefffffFfFffffffFfffffGggGggggggggGGggggggaAaaaaAaaaAaaaaaaaaAbbbbbbbbBbbbBbbbbBbbcccccCCccccccccCccCc",
/* 4*/ "aaaaAAaaaaaaaaAaaAaabbbBbbbbbbBbBbbbbbbbcCcCccccccCcccccCccCddddddddDDdddddddDddeeEeeeEeeeeeeeeEeeeeffffFfffFffffFffffffgGGggggggggGggGgggggAaaaaaaAaAaaaaaaaaAaBbbbbbbBbbbbbBbbBbbbcccccCCcccccccCccccC",
/* 5*/ "aaaaAAaaaaaaaAaaaaAabbBbbbbbbbbBbbbbbbbbCcccCccccCcccccccCCcdddddddDddDdddddDdddeeeEeEeeeeeeeeEeEeeefffFfffffFffFfffffffgGGgggggggGggggGgggGaaaaaaaaAaaaaaaaaAaabBbbbbBbbbbbbbBBbbbbccccCccCcccccCcccccc",
/* 6*/ "aaaAaaAaaaaaAaaaaaaAbBbbbbbbbbBbBbbbbbbBcccccCccCccccccccCCcddddddDddddDdddDddddeeeeEeeeeeeeeEeeeEeeffFfffffffFFffffffffGggGgggggGggggggGgGgaaaaaaaAaAaaaaaaAaaabbBbbBbbbbbbbbBBbbbbcccCccccCcccCccccccc",
/* 7*/ "aaAaaaaAaaaAaaaaaaaaBbbbbbbbbBbbbBbbbbBbccccccCCccccccccCccCdddddDddddddDdDdddddeeeEeEeeeeeeEeeeeeEefFffffffffFFfffffffFggggGgggGggggggggGggaaaaaaAaaaAaaaaAaaaabbbBBbbbbbbbbBbbBbbbccCccccccCcCcccccccc",
/* 8*/ "1AaaaaaaAa1aaaaaaaaA2BbbbbbbBb2bbbBbbBbb3cccccCCcc3ccccCcccc4dddDddddd4ddDdddddd5eEeeeEeee5EeeeeeeeE6ffffffffF6fFfffffFf7ggggGgGgg7gggggGgGg1aaaaAaaaa1AaaAaaaaa2bbBBbbbbb2bBbbbbBbb3Ccccccccc3ccccccccC",
/* 9*/ "AaaaaaaaaAaaaaaaaaAabbBbbbbBbbbbbbbBBbbbcccccCccCcccccCcccccdDdDddddddddDdDdddddeEeeeeeEeeEeeeeeeeeEFfffffffFffffFfffFffggggggGggggggggGgggGaaaaAaaaaaaaAAaaaaaabbBbbBbbbbbBbbbbbbBbCccccccccCcCccccccCc",
/*10*/ "aaaaaaaaAaAaaaaaaAaabbbBbbBbbbbbbbbBBbbbccccCccccCcccCccccccddDddddddddDdddDddddEeeeeeeeEEeeeeeeeeEefFfffffFffffffFfFfffgggggGgGggggggGgggggAaaAaaaaaaaaAAaaaaaabBbbbbBbbbBbbbbbbbbBccccccccCcccCccccCcc",
/*11*/ "aaaaaaaAaaaAaaaaAaaabbbbBBbbbbbbbbBbbBbbcccCccccccCcCcccccccdDdDddddddDdddddDddDeeeeeeeeEEeeeeeeeEeeffFfffFffffffffFffffggggGgggGggggGggggggaAAaaaaaaaaAaaAaaaaaBbbbbbbBbBbbbbbbbbBbCccccccCcccccCccCccc",
/*12*/ "aaaaaaAaaaaaAaaAaaaabbbbBBbbbbbbbBbbbbBbccCccccccccCccccccccDdddDddddDdddddddDDdeeeeeeeEeeEeeeeeEeeefffFfFffffffffFfFfffgggGgggggGggGgggggggaAAaaaaaaaAaaaaAaaaAbbbbbbbbBbbbbbbbbBbbcCccccCcccccccCCcccc",
/*13*/ "AaaaaAaaaaaaaAAaaaaabbbBbbBbbbbbBbbbbbbBcCccccccccCcCccccccCdddddDddDddddddddDDdeeeeeeEeeeeEeeeEeeeeffffFffffffffFfffFffggGgggggggGGggggggggAaaAaaaaaAaaaaaaAaAabbbbbbbBbBbbbbbbBbbbccCccCccccccccCCcccc",
/*14*/ "aAaaAaaaaaaaaAAaaaaabbBbbbbBbbbBbbbbbbbbCccccccccCcccCccccCcddddddDDddddddddDddDeeeeeEeeeeeeEeEeeeeefffFfFffffffFfffffFfgGggggggggGGgggggggGaaaaAaaaAaaaaaaaaAaabbbbbbBbbbBbbbbBbbbbcccCCccccccccCccCccc",
/*15*/ "aaAAaaaaaaaaAaaAaaaabBbbbbbbBbBbbbbbbbbBcCccccccCcccccCccCccddddddDDdddddddDddddEeeeEeeeeeeeeEeeeeeeffFfffFffffFfffffffFGggggggggGggGgggggGgaaaaaAaAaaaaaaaaAaAabbbbbBbbbbbBbbBbbbbbcccCCcccccccCccccCcc",
/*16*/ "2bBBbbbbbb2BbbbbBbbb3ccccccccC3cccccccCc4dDddddDdd4ddddDDddd5eeeeEeeEe5eeeEeeeee6FfFffffff6fFfFfffff7GgggggGgg7ggggggggG1aaaaaaaAa1aaAaaaAaa2bbbbbBbbb2bbbbBbbbB3cccCccccc3cCCcccccc4dDddDdddd4DddddddDd",
/*17*/ "bBbbBbbbbbBbbbbbbBbBccccccccCcCccccccCccdddDddDddddddddDDdddeeeeEeeeeEeeeEeeeeeeffFffffffffFfffFffffGgggggggGGggggggggGgaAaaaaaAaaaaaaAaAaaabbbbbBbBbbbbbbBbbbbbCccCccccccccCCccccccdDddddDdddDddddddddD",
/*18*/ "BbbbbBbbbBbbbbbbbbBbcccccccCcccCccccCcccddddDDddddddddDddDddeeeEeeeeeeEeEeeeeeeefFfFffffffFfffffFffFggggggggGGgggggggGggaaAaaaAaaaaaaaaAaaaabbbbBbbbBbbbbBbbbbbbcCCccccccccCccCcccccDddddddDdDddddddddDd",
/*19*/ "bbbbbbBbBbbbbbbbbBbBccccccCcccccCccCccccddddDDdddddddDddddDdeeEeeeeeeeeEeeeeeeeeFfffFffffFfffffffFFfgggggggGggGgggggGgggaaaAaAaaaaaaaaAaAaaabbbBbbbbbBbbBbbbbbbbcCCcccccccCccccCcccCddddddddDddddddddDdd",
/*20*/ "bbbbbbbBbbbbbbbbBbbbCccccCcccccccCCcccccdddDddDdddddDddddddDeEeeeeeeeeEeEeeeeeeEfffffFffFffffffffFFfggggggGggggGgggGggggaaaaAaaaaaaaaAaaaAaabbBbbbbbbbBBbbbbbbbbCccCcccccCccccccCcCcdddddddDdDddddddDddd",
/*21*/ "bbbbbbBbBbbbbbbBbbbbcCccCccccccccCCcccccddDddddDdddDddddddddEeeeeeeeeEeeeEeeeeEeffffffFFffffffffFffFgggggGggggggGgGgggggaaaAaAaaaaaaAaaaaaAabBbbbbbbbbBBbbbbbbbBccccCcccCccccccccCccddddddDdddDddddDdddd",
/*22*/ "bbbbbBbbbBbbbbBbbbbbccCCccccccccCccCccccdDddddddDdDddddddddDeEeeeeeeEeeeeeEeeEeeffffffFFfffffffFffffGgggGggggggggGggggggaaAaaaAaaaaAaaaaaaaABbbbbbbbbBbbBbbbbbBbcccccCcCccccccccCcCcdddddDdddddDddDddddd",
/*23*/ "bbbbBbbbbbBbbBbbbbbbccCCcccccccCccccCcccDddddddddDddddddddDdeeEeeeeEeeeeeeeEEeeefffffFffFfffffFfffffgGgGggggggggGgGgggggaAaaaaaAaaAaaaaaaaaABbbbbbbbBbbbbBbbbBbbccccccCccccccccCcccCddddDdddddddDDdddddd",
/*24*/ "2bbBbbbbbb2BBbbbbbbb3CccCccccc3ccccccCcC4dddddddDd4ddddddDdd5eeEeeEeee5eeeeEEeee6fffFffffF6ffFffffff7gGggggggg7GgggGgggg1aaaaaaaAA1aaaaaaaAa2BbbbbbBbb2bbbBbBbbb3ccccCcCcc3cccCccccc4ddDdddddd4dDDdddddd",
/*25*/ "bbBbbbbbbbbBBbbbbbbbCccccCcccCccccccccCcdddddddDdddDddddDdddeeeeEEeeeeeeeeEeeEeefffFffffffFfFfffffffgGgGggggggGgggggGggGaaaaaaaaAAaaaaaaaAaabbBbbbBbbbbbbbbBbbbbccccCcccCccccCccccccdDDddddddddDddDddddd",
/*26*/ "BBbbbbbbbbBbbBbbbbbBccccccCcCccccccccCcCddddddDdddddDddDddddeeeeEEeeeeeeeEeeeeEeffFffffffffFffffffffGgggGggggGgggggggGGgaaaaaaaAaaAaaaaaAaaabbbBbBbbbbbbbbBbBbbbcccCcccccCccCcccccccdDDdddddddDddddDdddD",
/*27*/ "BBbbbbbbbBbbbbBbbbBbcccccccCccccccccCcccDddddDdddddddDDdddddeeeEeeEeeeeeEeeeeeeEfFffffffffFfFffffffFgggggGggGggggggggGGgaaaaaaAaaaaAaaaAaaaabbbbBbbbbbbbbBbbbBbbccCcccccccCCccccccccDddDdddddDddddddDdDd",
/*28*/ "bbBbbbbbBbbbbbbBbBbbccccccCcCccccccCccccdDddDddddddddDDdddddeeEeeeeEeeeEeeeeeeeeFffffffffFfffFffffFfggggggGGggggggggGggGaaaaaAaaaaaaAaAaaaaabbbBbBbbbbbbBbbbbbBbcCccccccccCCcccccccCddddDdddDddddddddDdd",
/*29*/ "bbbBbbbBbbbbbbbbBbbbcccccCcccCccccCcccccddDDddddddddDddDddddeEeeeeeeEeEeeeeeeeeEfFffffffFfffffFffFffggggggGGgggggggGggggAaaaAaaaaaaaaAaaaaaabbBbbbBbbbbBbbbbbbbBCccccccccCccCcccccCcdddddDdDddddddddDdDd",
/*30*/ "bbbbBbBbbbbbbbbBbBbbccccCcccccCccCccccccddDDdddddddDddddDdddEeeeeeeeeEeeeeeeeeEeffFffffFfffffffFFfffgggggGggGgggggGgggggaAaAaaaaaaaaAaAaaaaabBbbbbbBbbBbbbbbbbbBCcccccccCccccCcccCccddddddDddddddddDdddD",
/*31*/ "bbbbbBbbbbbbbbBbbbBbcccCcccccccCCcccccccdDddDdddddDddddddDdDeeeeeeeeEeEeeeeeeEeefffFffFffffffffFFfffggggGggggGgggGggggggaaAaaaaaaaaAaaaAaaaaBbbbbbbbBBbbbbbbbbBbcCcccccCccccccCcCcccdddddDdDddddddDddddd",
/*32*/ "3cccCcCccc3ccCcccccC4dDddddddd4DDddddddd5eeeeEeeeE5eeeeeeeEe6ffffffFff6FffffFfff7gggGGgggg7gggGggGgg1aaAaaaaaa1aAaaaaaaa2BbBbbbbbb2bbbbbBbbB3cccccccCC3ccccccCcc4dDdddDddd4ddddDdddd5eeeEeeeEe5eeEeeeeee",
/*33*/ "cccCcccCccccCcccccccDDddddddddDddDdddddDeeeeeeEeEeeeeeeeeEeEffffffFfffffFffFffffggggGGgggggggGggggGgaaAaaaaaaaaAaaaaaaaaBbbbBbbbbBbbbbbbbBBbcccccccCccCcccccCcccdddDdDddddddddDdDdddeeeEeeeeeEeeEeeeeeee",
/*34*/ "ccCcccccCccCccccccccDDdddddddDddddDdddDdeeeeeeeEeeeeeeeeEeeeFffffFfffffffFFfffffgggGggGgggggGggggggGaAaaaaaaaaAaAaaaaaaAbbbbbBbbBbbbbbbbbBBbccccccCccccCcccCccccddddDddddddddDdddDddeeEeeeeeeeEEeeeeeeee",
/*35*/ "cCcccccccCCccccccccCddDdddddDddddddDdDddeeeeeeEeEeeeeeeEeeeefFffFffffffffFFfffffggGggggGgggGggggggggAaaaaaaaaAaaaAaaaaAabbbbbbBBbbbbbbbbBbbBcccccCccccccCcCcccccdddDdDddddddDdddddDdeEeeeeeeeeEEeeeeeeeE",
/*36*/ "CccccccccCCcccccccCcdddDdddDddddddddDdddeeeeeEeeeEeeeeEeeeeeffFFffffffffFffFffffgGggggggGgGggggggggGaAaaaaaaAaaaaaAaaAaabbbbbbBBbbbbbbbBbbbbCcccCccccccccCccccccddDdddDddddDdddddddDEeeeeeeeeEeeEeeeeeEe",
/*37*/ "ccccccccCccCcccccCccddddDdDddddddddDdDddeeeeEeeeeeEeeEeeeeeeffFFfffffffFffffFfffGggggggggGggggggggGgaaAaaaaAaaaaaaaAAaaabbbbbBbbBbbbbbBbbbbbcCcCccccccccCcCcccccdDdddddDddDddddddddDEeeeeeeeEeeeeEeeeEee",
/*38*/ "cccccccCccccCcccCcccdddddDddddddddDdddDdeeeEeeeeeeeEEeeeeeeefFffFfffffFffffffFfFggggggggGgGggggggGggaaaAaaAaaaaaaaaAAaaabbbbBbbbbBbbbBbbbbbbccCccccccccCcccCccccDdddddddDDddddddddDdeEeeeeeEeeeeeeEeEeee",
/*39*/ "CcccccCccccccCcCccccddddDdDddddddDdddddDeeEeeeeeeeeEEeeeeeeeFffffFfffFffffffffFfgggggggGgggGggggGgggaaaaAAaaaaaaaaAaaAaabbbBbbbbbbBbBbbbbbbbcCcCccccccCcccccCccCddddddddDDdddddddDddeeEeeeEeeeeeeeeEeeee",
/*40*/ "3CcccCcccc3cccCccccc4ddDdddDdd4dDddddddd5Eeeeeeeee5eeEeeeeeE6fffffFfFf6ffffffFfF7gggggGggg7gGggGgggg1aaaAAaaaa1aaAaaaaAa2bBbbbbbbb2Bbbbbbbbb3cccCccccC3ccccccCCc4ddddddDdd4dddddDddd5eeEeEeeee5eeeEeEeee",
/*41*/ "ccCcCccccccccCcCccccddDdddddDddDddddddddEEeeeeeeeEeeeeEeeeEefffffffFffffffffFfffGggggGgggggggGGgggggaaaAaaAaaaaaAaaaaaaAbBbbbbbbbbBbBbbbbbbBcccccCccCccccccccCCcddddddDddddDdddDddddeeeeEeeeeeeeeEeeeEee",
/*42*/ "cccCccccccccCcccCcccdDdddddddDDddddddddDeeEeeeeeEeeeeeeEeEeeffffffFfFffffffFffffgGggGggggggggGGgggggaaAaaaaAaaaAaaaaaaaaBbbbbbbbbBbbbBbbbbBbccccccCCccccccccCccCdddddDddddddDdDdddddeeeEeEeeeeeeEeeeeeEe",
/*43*/ "ccCcCccccccCcccccCccDddddddddDDdddddddDdeeeEeeeEeeeeeeeeEeeefffffFfffFffffFfffffggGGggggggggGggGggggaAaaaaaaAaAaaaaaaaaAbBbbbbbbBbbbbbBbbBbbccccccCCcccccccCccccDdddDddddddddDddddddeeEeeeEeeeeEeeeeeeeE",
/*44*/ "cCcccCccccCcccccccCCddddddddDddDdddddDddeeeeEeEeeeeeeeeEeEeeffffFfffffFffFffffffggGGgggggggGggggGgggAaaaaaaaaAaaaaaaaaAabbBbbbbBbbbbbbbBBbbbcccccCccCcccccCcccccdDdDddddddddDdDdddddeEeeeeeEeeEeeeeeeeeE",
/*45*/ "CcccccCccCccccccccCCdddddddDddddDdddDdddeeeeeEeeeeeeeeEeeeEefffFfffffffFFfffffffgGggGgggggGggggggGgGaaaaaaaaAaAaaaaaaAaabbbBbbBbbbbbbbbBBbbbccccCccccCcccCccccccddDddddddddDdddDddddEeeeeeeeEEeeeeeeeeEe",
/*46*/ "cccccccCCccccccccCccDdddddDddddddDdDddddeeeeEeEeeeeeeEeeeeeEffFffffffffFFfffffffGggggGgggGggggggggGgaaaaaaaAaaaAaaaaAaaabbbbBBbbbbbbbbBbbBbbcccCccccccCcCcccccccdDdDddddddDdddddDddDeeeeeeeeEEeeeeeeeEee",
/*47*/ "cccccccCCcccccccCcccdDdddDddddddddDdddddeeeEeeeEeeeeEeeeeeeeFFffffffffFffFfffffFggggggGgGggggggggGgGaaaaaaAaaaaaAaaAaaaabbbbBBbbbbbbbBbbbbBbccCccccccccCccccccccDdddDddddDdddddddDDdeeeeeeeEeeEeeeeeEeee",
/*48*/ "4dddddDddD4ddddDdddd5eEeEeeeee5eeEeEeeee6fFfffffFf6Fffffffff7GgggggggG7gggGgggGg1aaaaaaAaa1aaaaaAaaa2bbbbBbbbb2bbBBbbbbb3ccCccCccc3cCccccccC4Ddddddddd4dDddddddD5eeeeEeeEe5eeeeeeEEe6fffffFfff6FfffFffff",
/*49*/ "dddddDddddDdddDdddddeeeEeeeeeeeeEeeeEeeefFfffffffFFffffffffFggGgggggGggggggGgGggaaaaaaAaAaaaaaaAaaaabBbbBbbbbbbbbBBbbbbbccCccccCcccCccccccccDddddddddDdddDddddDdeeeeeeEEeeeeeeeeEeeEfffffFffffffFfFfffff",
/*50*/ "ddddDddddddDdDddddddeeEeEeeeeeeEeeeeeEeeFffffffffFFfffffffFfgggGgggGggggggggGgggaaaaaAaaaAaaaaAaaaaabbBBbbbbbbbbBbbBbbbbcCccccccCcCccccccccCdDddddddDdddddDddDddeeeeeeEEeeeeeeeEeeeeFfffFffffffffFffffff",
/*51*/ "dddDddddddddDdddddddeEeeeEeeeeEeeeeeeeEEffffffffFffFfffffFffggggGgGggggggggGgGggaaaaAaaaaaAaaAaaaaaabbBBbbbbbbbBbbbbBbbbCccccccccCccccccccCcddDddddDdddddddDDdddeeeeeEeeEeeeeeEeeeeefFfFffffffffFfFfffff",
/*52*/ "DdDddddddddDdDddddddEeeeeeEeeEeeeeeeeeEEfffffffFffffFfffFfffgggggGggggggggGgggGgaaaAaaaaaaaAAaaaaaaabBbbBbbbbbBbbbbbbBbBccccccccCcCccccccCccdddDddDddddddddDDdddeeeeEeeeeEeeeEeeeeeeffFffffffffFfffFffff",
/*53*/ "dDddddddddDdddDddddDeeeeeeeEEeeeeeeeeEeeFfffffFffffffFfFffffggggGgGggggggGgggggGaaAaaaaaaaaAAaaaaaaaBbbbbBbbbBbbbbbbbbBbcccccccCcccCccccCcccddddDDddddddddDddDddeeeEeeeeeeEeEeeeeeeefFfFffffffFfffffFffF",
/*54*/ "DdDddddddDdddddDddDdeeeeeeeEEeeeeeeeEeeefFfffFffffffffFfffffgggGgggGggggGgggggggAAaaaaaaaaAaaAaaaaaAbbbbbbBbBbbbbbbbbBbBccccccCcccccCccCccccddddDDdddddddDddddDdeeEeeeeeeeeEeeeeeeeeFfffFffffFfffffffFFf",
/*55*/ "dddDddddDdddddddDDddeeeeeeEeeEeeeeeEeeeeffFfFffffffffFfFffffggGgggggGggGggggggggAAaaaaaaaAaaaaAaaaAabbbbbbbBbbbbbbbbBbbbCccccCcccccccCCcccccdddDddDdddddDddddddDeEeeeeeeeeEeEeeeeeeEfffffFffFffffffffFFf",
/*56*/ "4dddDddDdd4dddddDDdd5eeeeEeeee5eeeEeeeee6ffFffffff6fFfffFfff7GgggggggG7ggggggggG1aAaaaaaAa1aaaaAaAaa2bbbbbBbBb2bbbbBbbbb3CccCccccc3ccCCccccc4dDddddDdd4Ddddddddd5eeeeeeeeE5eeEeeeeEe6fffffFFff6fffffFffF",
/*57*/ "dddddDDddddddddDddDdeeeeEeeeeeeEeEeeeeeeffFfFffffffFfffffFffGggggggggGGgggggggGgaaaAaaaAaaaaaaaaAaaabbbbbBbbbBbbbbBbbbbbccCCccccccccCccCccccdDddddddDdDddddddddDeEeeeeeeEeeeeeEeeEeeffffffFFfffffffFffff",
/*58*/ "dddddDDdddddddDddddDeeeEeeeeeeeeEeeeeeeefFfffFffffFfffffffFFggggggggGggGgggggGggaaaaAaAaaaaaaaaAaAaabbbbBbbbbbBbbBbbbbbbccCCcccccccCccccCcccDddddddddDddddddddDdeeEeeeeEeeeeeeeEEeeefffffFffFfffffFfffff",
/*59*/ "ddddDddDdddddDddddddEeEeeeeeeeeEeEeeeeeeFfffffFffFffffffffFFgggggggGggggGgggGgggaaaaaAaaaaaaaaAaaaAabbbBbbbbbbbBBbbbbbbbcCccCcccccCccccccCcCddddddddDdDddddddDddeeeEeeEeeeeeeeeEEeeeffffFffffFfffFffffff",
/*60*/ "dddDddddDdddDdddddddeEeeeeeeeeEeeeEeeeeEfffffffFFffffffffFffGgggggGggggggGgGggggaaaaAaAaaaaaaAaaaaaAbbBbbbbbbbbBBbbbbbbbCccccCcccCccccccccCcdddddddDdddDddddDdddeeeeEEeeeeeeeeEeeEeefffFffffffFfFfffffff",
/*61*/ "ddDddddddDdDddddddddEeEeeeeeeEeeeeeEeeEefffffffFFfffffffFfffgGgggGggggggggGgggggaaaAaaaAaaaaAaaaaaaaBBbbbbbbbbBbbBbbbbbBccccccCcCccccccccCcCddddddDdddddDddDddddeeeeEEeeeeeeeEeeeeEeffFffffffffFffffffff",
/*62*/ "dDddddddddDddddddddDeeeEeeeeEeeeeeeeEEeeffffffFffFfffffFffffggGgGggggggggGgGggggaaAaaaaaAaaAaaaaaaaaBBbbbbbbbBbbbbBbbbBbcccccccCccccccccCcccDddddDdddddddDDdddddeeeEeeEeeeeeEeeeeeeEfFffffffffFfFffffffF",
/*63*/ "DddddddddDdDddddddDdeeeeEeeEeeeeeeeeEEeefffffFffffFfffFfffffgggGggggggggGgggGgggaAaaaaaaaAAaaaaaaaaAbbBbbbbbBbbbbbbBbBbbccccccCcCccccccCccccdDddDddddddddDDdddddeeEeeeeEeeeEeeeeeeeeFffffffffFfffFffffFf",
};
const map_def_t map_scroll = { 200, 64, rows, legend, &ts_scroll };
