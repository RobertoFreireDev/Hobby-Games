#pragma once
// Fast TTY logging. printf goes through the BIOS one character at a time and costs about
// 2.6 scanlines per character (a 60-char line eats half a frame). dbg::log formats into a
// buffer and, when running in PCSX-Redux, writes each byte to the emulator's debug port
// (0x1F802080, one store per char); elsewhere it falls back to the BIOS printf.
// Output lands in the same TTY log (build/<game>/test/tty.log).
namespace dbg {
void log(const char* fmt, ...) __attribute__((format(printf, 1, 2)));
bool fastPort();   // true when PCSX-Redux's debug port answers
}
