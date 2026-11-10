#include "audio.hpp"
#include <cstring>
#include <psxspu.h>
#include <hwregs_c.h>
namespace audio {
namespace {
// SPU ADPCM block = 16 bytes = 28 samples.
//  byte 0: shift (bits 0-3, 0 = loudest) | filter << 4 (0 = no prediction)
//  byte 1: flags 0x04 loop start, 0x01 loop end, 0x02 repeat (0x03 = jump back to loop start)
//  bytes 2..15: 28 signed 4-bit samples, low nibble first.
//  With shift 0 / filter 0 each nibble (-8..7) is the output sample * 4096.
constexpr int SAMPLES = 28, NOISE_BLOCKS = 32;
constexpr uint32_t SPU_BASE = 0x1010;     // first 4 KB + 16 bytes reserved by psxspu
alignas(4) uint8_t g_ram[(WAVE_COUNT - 1) * 2 * 16 + NOISE_BLOCKS * 16 + 64];
uint32_t g_addr[WAVE_COUNT];
struct Sfx { int16_t frames; int16_t step; int32_t hz; Wave w; };
Sfx g_sfx[24];

int8_t toneSample(Wave w, int i) {        // one period = 28 samples
    switch (w) {
    case SQUARE:   return i < 14 ? 6 : -6;
    case PULSE25:  return i < 7 ? 6 : -6;
    case SAW:      return int8_t(-7 + (i * 14) / 27);
    case TRIANGLE: return int8_t(i < 14 ? -7 + i : 7 - (i - 14));
    default:       return 0;
    }
}
void writeBlock(uint8_t* b, uint8_t flags, const int8_t* s) {
    b[0] = 0;
    b[1] = flags;
    for (int i = 0; i < 14; i++) b[2 + i] = uint8_t((s[2 * i] & 15) | ((s[2 * i + 1] & 15) << 4));
}
// Same as the SDK's SpuSetKey() macro, but as plain statements: the macro's comma
// expression on volatile registers triggers -Wvolatile in C++20.
void keyOn(int v)  { const uint32_t m = 1u << v; SPU_KEY_ON1  = uint16_t(m); SPU_KEY_ON2  = uint16_t(m >> 16); }
void keyOff(int v) { const uint32_t m = 1u << v; SPU_KEY_OFF1 = uint16_t(m); SPU_KEY_OFF2 = uint16_t(m >> 16); }
void setPitch(int v, Wave w, int hz) {
    int rate = (w == NOISE) ? hz : hz * SAMPLES;   // NOISE: hz is the sample rate
    if (rate > 176400) rate = 176400;
    if (rate < 1) rate = 1;
    SPU_CH_FREQ(v) = getSPUSampleRate(rate);
}
}  // namespace

void init() {
    SpuInit();
    std::memset(g_ram, 0, sizeof(g_ram));
    uint8_t* p = g_ram;
    int8_t s[SAMPLES];
    for (int w = 0; w < NOISE; w++) {     // tone = 2 identical blocks: loop start, loop end
        for (int i = 0; i < SAMPLES; i++) s[i] = toneSample(Wave(w), i);
        g_addr[w] = SPU_BASE + uint32_t(p - g_ram);
        writeBlock(p, 0x04, s); p += 16;
        writeBlock(p, 0x03, s); p += 16;
    }
    uint32_t lfsr = 0xACE1u;
    g_addr[NOISE] = SPU_BASE + uint32_t(p - g_ram);
    for (int blk = 0; blk < NOISE_BLOCKS; blk++) {
        for (int i = 0; i < SAMPLES; i++) {
            lfsr ^= lfsr << 13; lfsr ^= lfsr >> 17; lfsr ^= lfsr << 5;
            s[i] = int8_t(int(lfsr & 15) - 8);
        }
        writeBlock(p, blk == 0 ? 0x04 : (blk == NOISE_BLOCKS - 1 ? 0x03 : 0x00), s);
        p += 16;
    }
    SpuSetTransferMode(SPU_TRANSFER_BY_DMA);
    SpuSetTransferStartAddr(SPU_BASE);
    SpuWrite(reinterpret_cast<const uint32_t*>(g_ram), (sizeof(g_ram) + 63) & ~63u);
    SpuIsTransferCompleted(SPU_TRANSFER_WAIT);
}

void play(int v, Wave w, int hz, int vol) {
    g_sfx[v].frames = 0;                           // a plain play() is not timed
    keyOff(v);
    setPitch(v, w, hz);
    SPU_CH_ADDR(v)  = getSPUAddr(g_addr[w]);
    SPU_CH_VOL_L(v) = uint16_t(vol);
    SPU_CH_VOL_R(v) = uint16_t(vol);
    SPU_CH_ADSR1(v) = 0x00ff;   // fast attack, full sustain level
    SPU_CH_ADSR2(v) = 0x0000;   // hold until key off
    keyOn(v);
}
void stop(int v) { g_sfx[v].frames = 0; keyOff(v); }

void sfx(int v, Wave w, int hz, int hzStep, int frames, int vol) {
    play(v, w, hz, vol);
    g_sfx[v] = { int16_t(frames), int16_t(hzStep), hz, w };
}

void update() {
    for (int v = 0; v < 24; v++) {
        Sfx& s = g_sfx[v];
        if (s.frames <= 0) continue;
        if (--s.frames == 0) { keyOff(v); continue; }
        if (s.step) { s.hz += s.step; setPitch(v, s.w, s.hz); }
    }
}
}  // namespace audio
