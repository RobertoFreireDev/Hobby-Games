#include "engine/engine.h"
/* Level theme: G major, fpt 7 = 128 BPM, loop 64 ticks (drums 16) */

static const uint8_t ch1[] = {           /* sustained harmony */
    INST(INST_SOFT), MUS_LOOP_POINT,
    N(B4,L2), N(A4,L2),                                             /* bar 1: 16 */
    N(G4,L2), N(D4,L2),                                             /* bar 2: 16 */
    N(E4,L2), N(Fs4,L2),                                            /* bar 3: 16 */
    N(E4,L2), N(D4,L2),                                             /* bar 4: 16 */
    MUS_LOOP
};
static const uint8_t ch2[] = {           /* melody */
    INST(INST_LEAD), MUS_LOOP_POINT,
    N(G4,L8), N(B4,L8), N(D5,L8), N(G5,L8), N(Fs5,L8), N(D5,L8), N(E5,L4),   /* bar 1: 16 */
    N(D5,L8), N(B4,L8), N(C5,L8), N(A4,L8), N(B4,L4), N(G4,L4),              /* bar 2: 16 */
    N(C5,L8), N(E5,L8), N(G5,L8), N(E5,L8), N(D5,L8), N(Fs5,L8), N(A5,L4),   /* bar 3: 16 */
    N(G5,L8), N(Fs5,L8), N(E5,L8), N(D5,L8), N(G5,L2),                       /* bar 4: 16 */
    MUS_LOOP
};
static const uint8_t ch3[] = {           /* bass */
    INST(WAVE_TRI), MUS_LOOP_POINT,
    N(G2,L4), N(D3,L4), N(G2,L4), N(D3,L4),                         /* bar 1: 16 */
    N(E2,L4), N(B2,L4), N(E2,L4), N(B2,L4),                         /* bar 2: 16 */
    N(C3,L4), N(G2,L4), N(D3,L4), N(A2,L4),                         /* bar 3: 16 */
    N(E2,L4), N(B2,L4), N(G2,L4), N(D3,L4),                         /* bar 4: 16 */
    MUS_LOOP
};
static const uint8_t ch4[] = {           /* drums */
    MUS_LOOP_POINT,
    D(KICK,L8), D(HAT,L8), D(SNARE,L8), D(HAT,L8),                  /* 8 */
    D(KICK,L8), D(KICK,L8), D(SNARE,L8), D(OHAT,L8),                /* 8 */
    MUS_LOOP
};
const song_t mus_level = { 7, { ch1, ch2, ch3, ch4 } };
