// mkharness.js — builds _test.p8 = game.p8 with driver.lua appended to __lua__.
// _test.p8 is build output; delete it when done.
// run: node games/gridlock/mkharness.js
const fs = require('fs');
const p = f => __dirname + '/' + f;
// the driver replays each level's optimal solution, encoded as piece+direction pairs
const IX = '0123456789abcdefghijklmnopqrstuvwxyz', DIR = { '-1,0': 'l', '1,0': 'r', '0,-1': 'u', '0,1': 'd' };
const sols = JSON.parse(fs.readFileSync(p('solutions.json'), 'utf8'))
  .map(path => path.map(([i, dx, dy]) => IX[i + 1] + DIR[dx + ',' + dy]).join('')).join(',');
const drv = fs.readFileSync(p('driver.lua'), 'utf8').replace('__SOLS__', sols);
const cart = fs.readFileSync(p('game.p8'), 'utf8');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
fs.writeFileSync(p('_test.p8'), cart.slice(0, i) + drv + '\n' + cart.slice(i));
console.log('harness written');
