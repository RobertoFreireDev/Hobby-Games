#include <cstdio>
#include "gfx.hpp"
#include "input.hpp"
#include "audio.hpp"
#include "fixed.hpp"

static const char* const HERO[16] = {
    "......1111......", ".....122221.....", "....12222221....", "....12322321....",
    "....12222221....", ".....122221.....", "......1441......", "....11444411....",
    "...1444444441...", "...1414444141...", "...1.144441.1...", ".....144441.....",
    ".....15..51.....", ".....15..51.....", "....155..551....", "....111..111....",
};
static const uint16_t HERO_PAL[16] = {
    0, gfx::rgb15(0, 0, 0) | 0x8000, gfx::rgb15(255, 204, 170), gfx::rgb15(40, 40, 90),
    gfx::rgb15(220, 50, 50), gfx::rgb15(60, 60, 200),
};

int main() {
    gfx::init(20, 24, 48);
    input::init();
    audio::init();
    std::printf("BOOT OK\n");

    const gfx::Texture hero = gfx::uploadSprite(HERO, 16, 16, HERO_PAL);
    fx x = 152_fx, y = 112_fx;
    const fx speed = 1.5_fx;
    int frame = 0;

    for (;;) {
        input::update();
        if (input::held(0, PAD_LEFT))  x -= speed;
        if (input::held(0, PAD_RIGHT)) x += speed;
        if (input::held(0, PAD_UP))    y -= speed;
        if (input::held(0, PAD_DOWN))  y += speed;
        if (input::pressed(0, PAD_CROSS)) {
            audio::play(0, audio::SQUARE, 880, 0x1800);
            std::printf("CROSS frame=%d x=%d\n", frame, x.toInt());
        }
        if (input::released(0, PAD_CROSS)) audio::stop(0);

        gfx::rect(0, 200, 320, 40, 40, 120, 40);           // ground
        gfx::sprite(hero, x.toInt(), y.toInt());
        char buf[48];
        std::snprintf(buf, sizeof(buf), "FRAME %d  X %d", frame, x.toInt());
        gfx::text(8, 8, buf);
        gfx::flip();
        frame++;
    }
}
