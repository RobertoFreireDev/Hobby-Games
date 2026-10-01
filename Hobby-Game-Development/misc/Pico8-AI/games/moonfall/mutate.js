// mutate.js -- prove the suite can fail
//
//   node mutate.js
//
// Breaks one thing per copy of the cart and asserts every copy is caught.
// A mutant that survives is not luck, it is a hole in driver.lua.

'use strict';
const fs = require('fs');
const { spawnSync } = require('child_process');

const PICO8 = 'C:/Program Files (x86)/PICO-8/pico8.exe';
const cart = fs.readFileSync('game.p8', 'utf8');
const driver = fs.readFileSync('driver.lua', 'utf8');
const cut = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);

const MUTANTS = [
  ['landmarks stop blocking movement',
   ' if cells[c]>=1 and cells[c]<=11 then sfx(1) return end', ' if false then sfx(1) return end'],
  ['a conversation costs one tick, not two',
   ' addtick(2)\n setpage(1)', ' addtick(1)\n setpage(1)'],
  ['the clock is allowed past nightfall',
   ' tk=min(40,tk+n)', ' tk=tk+n'],
  ['the day starts at the wrong hour',
   ' local m=480+tk*15', ' local m=540+tk*15'],
  ['landmark names stop being substituted',
   '  o=o..(c=="~" and n or c=="^" and l or c)', '  o=o..(c=="~" and n or c)'],
  ['dialogue wraps too wide for the panel',
   ' dlines=wrap(ctext(dv,stm[dv][p]),22)', ' dlines=wrap(ctext(dv,stm[dv][p]),40)'],
  ['hearing the same villager twice counts twice',
   ' if not heard[v] then\n  heard[v]=true\n  nheard+=1\n end',
   ' heard[v]=true\n nheard+=1'],
  ['a landmark decodes to the wrong sprite row',
   ' return v<9 and 30+v*2 or 46+v*2', ' return v<9 and 30+v*2 or 44+v*2'],
  ['the night record is read at the wrong stride',
   ' local o=(n-1)*77', ' local o=(n-1)*75'],
  ['a palette ramp step loses a colour',
   '01010111809111e0', '0101011180911e0'],
];

let survivors = 0;
for (const [name, from, to] of MUTANTS) {
  if (!cart.includes(from)) {
    console.log('SKIP  ' + name + '  (anchor not found -- update mutate.js)');
    survivors++;
    continue;
  }
  const mutated = cart.replace(from, to);
  const f = '_mut' + process.pid + '.p8';
  fs.writeFileSync(f, mutated.slice(0, cut) + driver + '\n' + mutated.slice(cut));
  const r = spawnSync(PICO8, ['-x', f], { encoding: 'utf8', timeout: 45000 });
  const out = (r.stdout || '') + (r.stderr || '');
  fs.rmSync(f, { force: true });
  const caught = !out.includes('ALL PASS');
  console.log((caught ? 'caught  ' : 'SURVIVED') + '  ' + name);
  if (!caught) survivors++;
}

console.log(survivors === 0
  ? '\nall ' + MUTANTS.length + ' mutants caught'
  : '\n' + survivors + ' mutant(s) survived -- the suite has a hole');
process.exit(survivors === 0 ? 0 : 1);
