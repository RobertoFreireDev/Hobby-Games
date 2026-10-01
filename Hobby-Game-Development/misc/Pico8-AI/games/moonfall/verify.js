// verify.js -- run game.p8 through the real engine with driver.lua appended
//
//   node verify.js
//
// A cart that has not been through `pico8 -x` is unverified, no matter how
// carefully the text was generated. printh arrives on stderr here, so both
// streams are read.

'use strict';
const fs = require('fs');
const { spawnSync } = require('child_process');

const PICO8 = 'C:/Program Files (x86)/PICO-8/pico8.exe';
const TEST = '_test.p8';

const cart = fs.readFileSync('game.p8', 'utf8');
const driver = fs.readFileSync('driver.lua', 'utf8');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
if (i < 0) throw new Error('no asset section found in game.p8');
fs.writeFileSync(TEST, cart.slice(0, i) + driver + '\n' + cart.slice(i));

const r = spawnSync(PICO8, ['-x', TEST], { encoding: 'utf8', timeout: 120000 });
const out = ((r.stdout || '') + (r.stderr || ''))
  .split('\n').map(l => l.replace(/^INFO:\s?/, '').trimEnd()).filter(Boolean);

fs.unlinkSync(TEST);

const noise = /^(RUNNING|WARNING|.*SDL|.*audio|.*joystick)/i;
const lines = out.filter(l => !noise.test(l));
console.log(lines.join('\n'));

const passed = lines.some(l => l === 'ALL PASS');
if (r.status !== 0) console.log('\npico8 exit code ' + r.status);
console.log(passed && r.status === 0 ? '\nOK' : '\nFAILED');
process.exit(passed && r.status === 0 ? 0 : 1);
