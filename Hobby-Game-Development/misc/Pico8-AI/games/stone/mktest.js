// build the headless harness carts: game.p8 with a test tab appended.
// each harness redefines _init or _update, and lua resolves globals at call
// time, so the appended definition is the one that runs.
//   node mktest.js && pico8 -x test.p8 && pico8 -x smoke.p8 && pico8 -x shot.p8
const fs = require('fs');
const path = require('path');

const cart = fs.readFileSync(path.join(__dirname, 'game.p8'), 'utf8');
const i = cart.indexOf('__gfx__');
if (i < 0) throw new Error('no __gfx__ section');

for (const name of ['test', 'smoke', 'shot']) {
  const t = fs.readFileSync(path.join(__dirname, name + '.lua'), 'utf8');
  fs.writeFileSync(path.join(__dirname, name + '.p8'),
    cart.slice(0, i) + '-->8\n-- ' + name + ' harness\n\n' + t + '\n' + cart.slice(i));
  console.log('wrote ' + name + '.p8');
}
