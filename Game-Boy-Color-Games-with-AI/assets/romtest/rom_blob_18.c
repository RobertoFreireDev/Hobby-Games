#pragma bank 255
#include "engine/engine.h"
#include "rom_blob.h"
/* ROM stress data: one full bank with pattern 18 (see rom_blob.h) */
BANKREF(rom_blob_18)
const uint8_t rom_blob_18[BLOB_SIZE] = { BLOB_DATA(18) };
