#ifndef ROMCOPY_H
#define ROMCOPY_H
#include "engine/engine.h"

/* Copies n bytes of const data that lives in ROM bank `bank` to RAM (PLAY GAME 2: world screens, the overworld
   tileset). NOT banked on purpose: it switches the 0x4000-0x7FFF window, which would unmap the caller if this
   code lived in a switchable bank. Restores the caller's bank. */
void rom_copy(void *dst, const void *src, uint16_t n, uint8_t bank);
#endif
