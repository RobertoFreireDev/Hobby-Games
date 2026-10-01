// build the headless harness carts: game.p8 with a test tab appended.
// lua resolves globals at call time, so an appended definition replaces the
// game's own — that is what lets the drivers fake input and stub _draw.
//   node mktest.js && pico8 -x test.p8 && pico8 -x smoke.p8 && pico8 -x shot.p8
'use strict';
const fs = require('fs');
const path = require('path');
const CR = String.fromCharCode(13);

const cart = fs.readFileSync(path.join(__dirname, 'game.p8'), 'utf8').split(CR).join('');
const i = cart.indexOf('__gfx__');
if (i < 0) throw new Error('no __gfx__ section');

for (const name of process.argv.slice(2).length ? process.argv.slice(2) : ['test', 'smoke', 'shot', 'audio', 'perf']) {
  const t = fs.readFileSync(path.join(__dirname, name + '.lua'), 'utf8').split(CR).join('');
  fs.writeFileSync(path.join(__dirname, name + '.p8'),
    cart.slice(0, i) + '-->8\n-- ' + name + ' harness\n\n' + t + '\n' + cart.slice(i));
  console.log('wrote ' + name + '.p8');
}
