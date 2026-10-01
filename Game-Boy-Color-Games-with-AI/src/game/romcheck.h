#ifndef ROMCHECK_H
#define ROMCHECK_H
#include "engine/engine.h"

/* Verifies `count` 256-byte groups of ROM stress blob n (1-24), starting at group g, against the
   pattern of assets/romtest/rom_blob.h. Returns the number of wrong bytes (0 = OK).
   NOT banked on purpose: it switches the 0x4000-0x7FFF window to the blob's bank, which would unmap
   the caller if this code lived in a switchable bank. */
uint16_t romcheck_groups(uint8_t bank, const uint8_t *blob, uint8_t n, uint8_t g, uint8_t count);
#endif
