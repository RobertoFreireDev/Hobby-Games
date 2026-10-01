#include "engine/engine.h"
/* Game over: A minor, fpt 10 = 90 BPM, 32 ticks, no loop, no drums */

static const uint8_t ch1[] = {
    INST(INST_SOFT),
    N(C5,L4), N(B4,L4), N(A4,L4), N(Gs4,L4), N(E4,L1),             /* 32 */
    MUS_END
};
static const uint8_t ch2[] = {
    INST(INST_LEAD),
    N(E5,L4), N(D5,L4), N(C5,L4), N(B4,L4), N(A4,L1),              /* 32 */
    MUS_END
};
static const uint8_t ch3[] = {
    INST(WAVE_TRI),
    N(A2,L2), N(E2,L2), N(A2,L1),                                   /* 32 */
    MUS_END
};
const song_t mus_over = { 10, { ch1, ch2, ch3, 0 } };
