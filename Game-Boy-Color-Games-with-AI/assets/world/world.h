#ifndef WORLD_FORMAT_H
#define WORLD_FORMAT_H
#include <stdint.h>
/* PLAY GAME 2 overworld format (game-specific folder, delete with the game).
   The world is WORLD_W x WORLD_H screens; a screen is 10 x 9 metatiles of 16x16 px (one Game Boy screen).
   Each world_rNN.c holds one row of screens and fills exactly one 16 KB ROM bank:
   screen x of row y = world_rNN[x], bank BANK(world_rNN). src/game/overworld.c streams them into a 3x3 ring in WRAM. */

#define WORLD_W 128                 /* screens */
#define WORLD_H 96
#define SCR_MW 10                   /* metatiles per screen */
#define SCR_MH 9

typedef struct {
    char map[SCR_MW * SCR_MH + 1];  /* 9 rows of 10 metatile chars (ow_metatiles), then the string's NUL */
    char name[13];                  /* area name for the HUD, up to 12 chars */
    char sign[24];                  /* text of this screen's sign ('S'), up to 23 chars; "" = no sign */
} wscreen_t;                        /* 128 bytes: 128 screens = 16384 bytes = one bank */

/* metatile: 2x2 tiles, legend of the world map chars (assets/tilesets/ts_overworld.c) */
typedef struct {
    char ch;
    uint8_t coll;                   /* COLL_SOLID or 0 */
    uint8_t tag;                    /* TAG_SIGN / TAG_DOOR (assets.h) or 0 */
    uint8_t tile[4];                /* tileset index: top-left, top-right, bottom-left, bottom-right */
    uint8_t attr[4];                /* BG palette | S_FLIPX | S_FLIPY */
} ow_metatile_t;
#define OW_TILES 68
#define OW_METATILES 19

/* player start: HAWKHOLM, plaza cell (4,4) of screen (62,45) */
#define WORLD_START_SX 62
#define WORLD_START_SY 45
#define WORLD_START_MX 4
#define WORLD_START_MY 4

/* X-macro over the 96 row files (externs in assets.h, bank table in src/game/world.c) */
#define WORLD_ROWS(X) \
    X(00) X(01) X(02) X(03) X(04) X(05) X(06) X(07) X(08) X(09) X(10) X(11) X(12) X(13) X(14) X(15) \
    X(16) X(17) X(18) X(19) X(20) X(21) X(22) X(23) X(24) X(25) X(26) X(27) X(28) X(29) X(30) X(31) \
    X(32) X(33) X(34) X(35) X(36) X(37) X(38) X(39) X(40) X(41) X(42) X(43) X(44) X(45) X(46) X(47) \
    X(48) X(49) X(50) X(51) X(52) X(53) X(54) X(55) X(56) X(57) X(58) X(59) X(60) X(61) X(62) X(63) \
    X(64) X(65) X(66) X(67) X(68) X(69) X(70) X(71) X(72) X(73) X(74) X(75) X(76) X(77) X(78) X(79) \
    X(80) X(81) X(82) X(83) X(84) X(85) X(86) X(87) X(88) X(89) X(90) X(91) X(92) X(93) X(94) X(95)
#endif
