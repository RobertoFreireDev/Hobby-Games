#include "log.hpp"
#include <cstdarg>
#include <cstdint>
#include <cstdio>

namespace dbg {
namespace {
constexpr uintptr_t PCSX_PORT = 0x1F802080;    // PCSX-Redux: read "PCSX", write = TTY putc
int g_fast = -1;                                // -1 = not probed yet
}

bool fastPort() {
    if (g_fast < 0)
        g_fast = *reinterpret_cast<volatile uint32_t*>(PCSX_PORT) == 0x58534350u ? 1 : 0;   // "PCSX"
    return g_fast == 1;
}

void log(const char* fmt, ...) {
    static char buf[256];
    va_list ap;
    va_start(ap, fmt);
    std::vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    if (!fastPort()) { std::printf("%s", buf); return; }
    volatile char* port = reinterpret_cast<volatile char*>(PCSX_PORT);
    for (const char* p = buf; *p; p++) *port = *p;
}
}  // namespace dbg
