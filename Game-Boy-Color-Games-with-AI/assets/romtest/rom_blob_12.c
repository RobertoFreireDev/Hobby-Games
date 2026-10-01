#pragma bank 255
#include "engine/engine.h"
#include "rom_blob.h"
/* ROM stress data: one full bank with pattern 12 (see rom_blob.h) */
BANKREF(rom_blob_12)
const uint8_t rom_blob_12[BLOB_SIZE] = { BLOB_DATA(12) };
