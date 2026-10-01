#!/bin/sh
# label.sh -- render the cart cover and splice it into game.p8's __label__.
set -e
awk '/^__gfx__/{exit}1' game.p8 > labelgen.p8
cat labelharness.txt >> labelgen.p8
awk '/^__gfx__/{f=1}f' game.p8 >> labelgen.p8
"C:/Program Files (x86)/PICO-8/pico8.exe" -x labelgen.p8 > label.raw 2>&1
grep -v '^RUNNING:' label.raw > label.txt
node ../../label-tool.js label.txt game.p8 label.png 3
