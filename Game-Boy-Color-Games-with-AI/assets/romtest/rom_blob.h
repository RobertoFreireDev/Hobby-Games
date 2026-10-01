#ifndef ROM_BLOB_H
#define ROM_BLOB_H
/* ROM stress data (memory test scene). Each rom_blob_NN.c fills one ROM bank with 62 groups of 256 bytes.
   Byte k of group g in blob n = k ^ BLOB_SEED(n, g): every bank holds a different, checkable pattern, so a
   wrong bank switch or a bad ROM byte shows up as a mismatch. src/game/romcheck.c verifies it. */
#include <stdint.h>
#define BLOB_GROUPS 62
#define BLOB_SIZE   (BLOB_GROUPS * 256)
#define BLOB_COUNT  24
#define BLOB_SEED(n, g) ((uint8_t)((n) * 29 + (g) * 13 + 7))

#define BV_(s, k)   ((uint8_t)((k) ^ (s)))
#define B4_(s, k)   BV_(s, k), BV_(s, (k) + 1), BV_(s, (k) + 2), BV_(s, (k) + 3)
#define B16_(s, k)  B4_(s, k), B4_(s, (k) + 4), B4_(s, (k) + 8), B4_(s, (k) + 12)
#define B64_(s, k)  B16_(s, k), B16_(s, (k) + 16), B16_(s, (k) + 32), B16_(s, (k) + 48)
#define G_(n, g)    B64_(BLOB_SEED(n, g), 0), B64_(BLOB_SEED(n, g), 64), B64_(BLOB_SEED(n, g), 128), B64_(BLOB_SEED(n, g), 192)
#define G8_(n, g)   G_(n, g), G_(n, (g) + 1), G_(n, (g) + 2), G_(n, (g) + 3), \
                    G_(n, (g) + 4), G_(n, (g) + 5), G_(n, (g) + 6), G_(n, (g) + 7)
/* 62 groups = 7 x 8 + 6 */
#define BLOB_DATA(n) G8_(n, 0), G8_(n, 8), G8_(n, 16), G8_(n, 24), G8_(n, 32), G8_(n, 40), G8_(n, 48), \
                     G_(n, 56), G_(n, 57), G_(n, 58), G_(n, 59), G_(n, 60), G_(n, 61)
#endif
