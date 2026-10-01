#!/bin/sh
# shot.sh <arg> <out.png> -- render one frame of game.p8 headlessly.
# <arg> is a level number, or "intro" for the title screen. _draw never runs
# under -x, so the harness calls the draw function itself and dumps pget().
set -e
awk '/^__gfx__/{exit}1' game.p8 > shot.p8
cat shotharness.txt >> shot.p8
awk '/^__gfx__/{f=1}f' game.p8 >> shot.p8
"C:/Program Files (x86)/PICO-8/pico8.exe" -x shot.p8 -p "$1" > shot.raw 2>&1
grep -v '^RUNNING:' shot.raw > shot.txt
node ../../label-tool.js shot.txt - "$2" 3
