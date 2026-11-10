#pragma once
#include <cstdint>
#include <psxpad.h>   // PAD_UP, PAD_CROSS, PAD_START, ... bit masks
namespace input {
void init();                 // after gfx::init()
void update();               // once per frame, before game logic
bool held(int port, uint16_t mask);
bool pressed(int port, uint16_t mask);    // went down this frame
bool released(int port, uint16_t mask);
bool connected(int port);
}
