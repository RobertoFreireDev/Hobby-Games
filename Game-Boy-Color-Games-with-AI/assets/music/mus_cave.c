#include "engine/engine.h"
/* Cave theme: A minor, fpt 9 = 100 BPM, loop 32 ticks (drums 16). CH1 is a fake echo one tick behind CH2 */

static const uint8_t ch1[] = {           /* echo */
    INST(INST_ECHO), MUS_LOOP_POINT,
    R(L16), N(A4,L4), N(C5,L4), N(E5,L4), N(D5,L4),                 /* bar 1: 1 + 16 */
    N(C5,L4), N(B4,L4), N(A4,7),                                    /* bar 2: 15 */
    MUS_LOOP
};
static const uint8_t ch2[] = {           /* melody */
    INST(INST_SOFT), MUS_LOOP_POINT,
    N(A4,L4), N(C5,L4), N(E5,L4), N(D5,L4),                         /* bar 1: 16 */
    N(C5,L4), N(B4,L4), N(A4,L2),                                   /* bar 2: 16 */
    MUS_LOOP
};
static const uint8_t ch3[] = {           /* bass */
    INST(WAVE_SOFTTRI), MUS_LOOP_POINT,
    N(A2,L2), N(E3,L2),                                             /* bar 1: 16 */
    N(F2,L2), N(E2,L2),                                             /* bar 2: 16 */
    MUS_LOOP
};
static const uint8_t ch4[] = {           /* drums */
    MUS_LOOP_POINT,
    D(HAT,L4), D(HAT,L4), D(TOM,L4), D(HAT,L4),                     /* 16 */
    MUS_LOOP
};
const song_t mus_cave = { 9, { ch1, ch2, ch3, ch4 } };
