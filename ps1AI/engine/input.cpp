#include "input.hpp"
#include <psxapi.h>
namespace input {
namespace {
uint8_t  g_raw[2][34];          // the BIOS writes here every VBlank: must stay alive
uint16_t g_now[2], g_prev[2];
bool     g_ok[2];
}
void init() { InitPAD(g_raw[0], 34, g_raw[1], 34); StartPAD(); ChangeClearPAD(0); }
void update() {
    for (int p = 0; p < 2; p++) {
        const PADTYPE* pad = reinterpret_cast<const PADTYPE*>(g_raw[p]);
        g_prev[p] = g_now[p];
        // stat 0 = OK; type 4 digital, 5 analog stick, 7 DualShock analog mode
        g_ok[p]  = pad->stat == 0 && (pad->type == 0x4 || pad->type == 0x5 || pad->type == 0x7);
        g_now[p] = g_ok[p] ? uint16_t(~pad->btn) : 0;   // hardware bits are active-low
    }
}
bool held(int p, uint16_t m)     { return (g_now[p] & m) != 0; }
bool pressed(int p, uint16_t m)  { return (g_now[p] & m) && !(g_prev[p] & m); }
bool released(int p, uint16_t m) { return !(g_now[p] & m) && (g_prev[p] & m); }
bool connected(int p)            { return g_ok[p]; }
}
