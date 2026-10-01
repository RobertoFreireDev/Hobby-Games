// mkshots.js — builds _shot.p8 = game.p8 with shotgen.lua appended to __lua__.
// Running it under `pico8 -x` writes one shot_<name>.p8l per screen (128 lines of
// 128 hex digits, the same encoding as __gfx__/__label__). Feed those to
// p8l-to-png.js to look at them, or to gen-label.js to make the cart label.
// _shot.p8 and the .p8l/.png files are build output; delete them when done.
// run: node games/gridlock/mkshots.js
const fs = require('fs');
const p = f => __dirname + '/' + f;
const cart = fs.readFileSync(p('game.p8'), 'utf8');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
fs.writeFileSync(p('_shot.p8'), cart.slice(0, i) + fs.readFileSync(p('shotgen.lua'), 'utf8') + '\n' + cart.slice(i));
console.log('shot harness written');
