// mklabelgen.js - build labelgen.p8 from labelgen.lua plus the game's own
// sprite sheet, so the cover art draws the real face glyphs with sspr rather
// than a second copy of them that could drift.
//   node mklabelgen.js
//   pico8.exe -x games/stone/labelgen.p8 > dump.txt 2>&1
//   node label-tool.js dump.txt games/stone/game.p8 games/stone/label.png 3
'use strict';
const fs = require('fs'), path = require('path');
const d = __dirname;

const cart = fs.readFileSync(path.join(d, 'game.p8'), 'utf8').split(/\r?\n/);
const g = cart.indexOf('__gfx__');
if (g < 0) throw new Error('no __gfx__ in game.p8');
let end = g + 1;
while (end < cart.length && /^[0-9a-f]{128}$/.test(cart[end])) end++;
const gfx = cart.slice(g, end);
if (gfx.length < 9) throw new Error('__gfx__ is only ' + (gfx.length - 1) + ' rows');

fs.writeFileSync(path.join(d, 'labelgen.p8'),
  'pico-8 cartridge // http://www.pico-8.com\nversion 43\n__lua__\n'
  + fs.readFileSync(path.join(d, 'labelgen.lua'), 'utf8') + '\n'
  + gfx.join('\n') + '\n', 'utf8');
console.log('labelgen.p8 written with ' + (gfx.length - 1) + ' gfx rows');
