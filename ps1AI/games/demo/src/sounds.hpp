#pragma once
// Sound effects (procedural, engine/audio). Voices: 0 jump, 1 land, 2 throw, 3-4 kick,
// 5 UI, 6-9 ball bounces, 10 reset.
#include "audio.hpp"
#include "util.hpp"

namespace sfx {
inline void jump()        { audio::sfx(0, audio::SQUARE, 260, 28, 12, 0x1400); }
inline void land(int spd) { audio::sfx(1, audio::NOISE, 9000, -500, 6, util::clamp(spd * 0x180, 0x600, 0x2000)); }
inline void headBump()    { audio::sfx(1, audio::SQUARE, 140, -6, 8, 0x1800); }
inline void throwBall()   { audio::sfx(2, audio::SAW, 900, -45, 12, 0x1200); }
inline void kick(bool hit) {
    audio::sfx(3, audio::NOISE, 14000, -900, 7, 0x2000);
    if (hit) audio::sfx(4, audio::TRIANGLE, 200, -8, 12, 0x3000);
}
inline void ui()          { audio::sfx(5, audio::PULSE25, 1320, 0, 4, 0x0e00); }
inline void bounce(int ball, int spd) {
    audio::sfx(6 + (ball & 3), audio::TRIANGLE, 330 + ball * 55 + spd * 12, -12, 7,
               util::clamp(spd * 0x200, 0x0400, 0x2400));
}
inline void reset()       { audio::sfx(10, audio::SQUARE, 880, -40, 16, 0x1000); }
}  // namespace sfx
