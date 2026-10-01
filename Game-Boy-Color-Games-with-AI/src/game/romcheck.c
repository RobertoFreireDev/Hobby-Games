#include "engine/engine.h"
#include "romcheck.h"
#include "romtest/rom_blob.h"

uint16_t romcheck_groups(uint8_t bank, const uint8_t *blob, uint8_t n, uint8_t g, uint8_t count) {
    uint8_t save = CURRENT_BANK;
    uint8_t s, k;
    uint16_t bad = 0;
    const uint8_t *p = blob + ((uint16_t)g << 8);
    SWITCH_ROM(bank);
    while (count--) {
        s = BLOB_SEED(n, g);
        g++;
        k = 0;
        do { if (*p++ != (uint8_t)(k ^ s)) bad++; } while (++k);
    }
    SWITCH_ROM(save);
    return bad;
}
