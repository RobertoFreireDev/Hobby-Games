#include "engine/engine.h"
#include <string.h>
#include "romcopy.h"

void rom_copy(void *dst, const void *src, uint16_t n, uint8_t bank) {
    uint8_t save = CURRENT_BANK;
    SWITCH_ROM(bank);
    memcpy(dst, src, n);
    SWITCH_ROM(save);
}
