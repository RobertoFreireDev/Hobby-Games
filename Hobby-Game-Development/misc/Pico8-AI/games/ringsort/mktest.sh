#!/bin/sh
# mktest.sh -- rebuild test.p8 from the current game.p8 plus the harness tail,
# then run it headlessly. The harness overrides _init/_update/_draw, so it must
# be appended after the game code (Lua resolves globals at call time).
set -e
awk '/^__gfx__/{exit}1' game.p8 > test.p8
cat testharness.txt >> test.p8
awk '/^__gfx__/{f=1}f' game.p8 >> test.p8
"C:/Program Files (x86)/PICO-8/pico8.exe" -x test.p8
