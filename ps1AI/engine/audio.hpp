#pragma once
#include <cstdint>
namespace audio {
enum Wave { SQUARE = 0, TRIANGLE, SAW, PULSE25, NOISE, WAVE_COUNT };
void init();                                             // after gfx::init()
void play(int voice, Wave w, int hz, int vol = 0x2000);  // voice 0..23, vol 0..0x3fff, loops
void stop(int voice);
// One-shot effect: plays for `frames` frames, changing pitch by `hzStep` Hz per frame
// (sweeps for jumps/lasers). Needs update() once per frame.
void sfx(int voice, Wave w, int hz, int hzStep, int frames, int vol = 0x2000);
void update();
}
