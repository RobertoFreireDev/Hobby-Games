#pragma bank 255
#include "engine/engine.h"
#include "rom_blob.h"
/* ROM stress data: one full bank with pattern 7 (see rom_blob.h) */
BANKREF(rom_blob_07)
const uint8_t rom_blob_07[BLOB_SIZE] = { BLOB_DATA(7) };
