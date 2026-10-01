#ifndef SAVE_H
#define SAVE_H
#include "engine/engine.h"

/* Battery-backed save in cartridge RAM at 0xA000 (MBC5 + RAM + battery, see build.sh -Wl-yt0x1B).
   The memory test only touches SRAM from SAVE_TEST_START up, so the save survives it. */
#define SAVE_TEST_START 0xA100

typedef struct {
    uint8_t magic[4];               /* 'L','A','B','1' */
    uint16_t boots;                 /* power-ons that reached the title */
    uint16_t saves;                 /* times the save sign was used */
    uint8_t best_coins;
    uint16_t best_frames;           /* fastest win with best_coins, in frames */
    uint8_t wins;
    uint8_t sum;                    /* checksum of every byte above */
} save_t;

extern save_t save;                 /* RAM copy */
extern uint8_t save_found;          /* 1 if SRAM held a valid save at the last save_load() */

void save_load(void) BANKED;        /* invalid or missing data -> defaults */
void save_write(void) BANKED;
#endif
