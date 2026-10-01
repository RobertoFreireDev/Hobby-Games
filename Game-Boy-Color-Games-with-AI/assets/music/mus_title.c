#include "engine/engine.h"
/* Title theme: C major, fpt 6 = 150 BPM, loop 32 ticks (drums 8) */

static const uint8_t ch1[] = {           /* harmony */
    INST(INST_SOFT), MUS_LOOP_POINT,
    N(E4,L4), N(G4,L4), N(D5,L4), N(B4,L4),                         /* bar 1: 16 */
    N(F4,L4), N(E4,L4), N(G4,L2),                                   /* bar 2: 16 */
    MUS_LOOP
};
static const uint8_t ch2[] = {           /* melody */
    INST(INST_LEAD), MUS_LOOP_POINT,
    N(C5,L8), N(E5,L8), N(G5,L8), N(C6,L8), N(B5,L4), N(G5,L4),     /* bar 1: 16 */
    N(A5,L8), N(G5,L8), N(E5,L8), N(D5,L8), N(C5,L2),               /* bar 2: 16 */
    MUS_LOOP
};
static const uint8_t ch3[] = {           /* bass */
    INST(WAVE_TRI), MUS_LOOP_POINT,
    N(C3,L4), N(C3,L4), N(G2,L4), N(G2,L4),                         /* bar 1: 16 */
    N(F2,L4), N(F2,L4), N(G2,L4), N(C3,L4),                         /* bar 2: 16 */
    MUS_LOOP
};
static const uint8_t ch4[] = {           /* drums */
    MUS_LOOP_POINT,
    D(KICK,L8), D(HAT,L8), D(SNARE,L8), D(HAT,L8),                  /* half bar: 8 */
    MUS_LOOP
};
const song_t mus_title = { 6, { ch1, ch2, ch3, ch4 } };
