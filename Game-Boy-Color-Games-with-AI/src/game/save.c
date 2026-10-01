#pragma bank 255
#include "engine/engine.h"
#include "save.h"

save_t save;
uint8_t save_found;

static uint8_t checksum(void) {
    const uint8_t *p = (const uint8_t *)&save;
    uint8_t i, s = 0x5A;
    for (i = 0; i < sizeof(save_t) - 1; i++) s = (uint8_t)((s << 1) | (s >> 7)) ^ p[i];
    return s;
}

void save_load(void) BANKED {
    uint8_t i;
    uint8_t *dst = (uint8_t *)&save;
    const uint8_t *src = (const uint8_t *)0xA000;
    ENABLE_RAM;
    SWITCH_RAM(0);
    for (i = 0; i < sizeof(save_t); i++) dst[i] = src[i];
    DISABLE_RAM;
    save_found = save.magic[0] == 'L' && save.magic[1] == 'A' && save.magic[2] == 'B' && save.magic[3] == '1'
                 && save.sum == checksum();
    if (!save_found) {
        for (i = 0; i < sizeof(save_t); i++) dst[i] = 0;
        save.magic[0] = 'L'; save.magic[1] = 'A'; save.magic[2] = 'B'; save.magic[3] = '1';
    }
}

void save_write(void) BANKED {
    uint8_t i;
    const uint8_t *src = (const uint8_t *)&save;
    uint8_t *dst = (uint8_t *)0xA000;
    save.sum = checksum();
    ENABLE_RAM;
    SWITCH_RAM(0);
    for (i = 0; i < sizeof(save_t); i++) dst[i] = src[i];
    DISABLE_RAM;
}
