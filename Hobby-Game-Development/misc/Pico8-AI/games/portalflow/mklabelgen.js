// mklabelgen.js — build labelgen.p8 = labelgen.lua + the game's own __gfx__,
// so the cover art is composed from the real tiles and the real logo.
//   node mklabelgen.js
//   rm -f lbl.p8l && pico8 -x labelgen.p8
//   node ../../label-tool.js lbl.p8l game.p8 label.png 3
'use strict';
const fs = require('fs');
const path = require('path');
const d = __dirname;
const CR = String.fromCharCode(13);

const cart = fs.readFileSync(path.join(d, 'game.p8'), 'utf8').split(CR).join('');
const g = /^__gfx__$/m.exec(cart);
if (!g) throw new Error('no __gfx__ in game.p8');
const from = g.index + g[0].length + 1;
const nx = cart.slice(from).search(/^__[a-z]+__$/m);
const gfx = cart.slice(from, nx < 0 ? cart.length : from + nx);

const lua = fs.readFileSync(path.join(d, 'labelgen.lua'), 'utf8').split(CR).join('');
fs.writeFileSync(path.join(d, 'labelgen.p8'),
  'pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n' +
  lua + (lua.endsWith('\n') ? '' : '\n') + '__gfx__\n' + gfx);
console.log('wrote labelgen.p8');
