#pragma bank 255
#include "engine/engine.h"
#include "rom_blob.h"
/* ROM stress data: one full bank with pattern 1 (see rom_blob.h) */
BANKREF(rom_blob_01)
const uint8_t rom_blob_01[BLOB_SIZE] = { BLOB_DATA(1) };
