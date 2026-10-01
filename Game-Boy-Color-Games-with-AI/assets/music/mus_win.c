#include "engine/engine.h"
/* Win jingle: C major, fpt 5 = 180 BPM, 20 ticks, no loop */

static const uint8_t ch1[] = {
    INST(INST_SOFT),
    N(E4,L8), N(G4,L8), N(C5,L8), N(E5,L4), N(E5,L8), N(E5,L2),     /* 20 */
    MUS_END
};
static const uint8_t ch2[] = {
    INST(INST_SQUARE),
    N(C5,L8), N(E5,L8), N(G5,L8), N(C6,L4), N(G5,L8), N(C6,L2),     /* 20 */
    MUS_END
};
static const uint8_t ch3[] = {
    INST(WAVE_TRI),
    N(C3,L4), N(G2,L4), N(E3,L4), N(C3,L2),                         /* 20 */
    MUS_END
};
static const uint8_t ch4[] = {
    D(KICK,L8), D(SNARE,L8), D(KICK,L8), D(SNARE,L4), D(KICK,L8), D(CRASH,L2),   /* 20 */
    MUS_END
};
const song_t mus_win = { 5, { ch1, ch2, ch3, ch4 } };
