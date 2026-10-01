// rotamaze - run tools/test.lua inside the real cart.
//   node test.js            run the rule tests
//   node test.js --mutants  break the cart on purpose, one break per copy,
//                           and check every mutant fails
'use strict';
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const DIR = path.join(__dirname, '..');
const PICO = 'C:/Program Files (x86)/PICO-8/pico8.exe';

function build(cartText, out) {
  const i = cartText.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
  const drv = fs.readFileSync(path.join(__dirname, 'test.lua'), 'utf8');
  fs.writeFileSync(out, cartText.slice(0, i) + drv + '\n' + cartText.slice(i));
}

function run(out) {
  const r = cp.spawnSync(PICO, ['-x', out], { encoding: 'utf8', timeout: 120000 });
  const lines = ((r.stdout || '') + (r.stderr || '')).split(/\r?\n/)
    .map(l => l.replace(/^INFO:\s*/, '').trim())
    .filter(l => l && !/^RUNNING/.test(l));
  return lines;
}

// each mutant is [description, find, replace] - a single real behaviour change
const MUTANTS = [
  ['blocked press charges a movement', ' if blk then\n  pf=d bt=4 ft=3', ' if blk then\n  pf=d bt=4 ft=3 mov-=1'],
  ['rotation is counter-clockwise', 'return (w*2)%16+w\\8', 'return (w\\2)+(w%2)*8'],
  ['free turn is pushed to history', ' if blk then\n  pf=d', ' if blk then\n  add(hs,{0,pc,pr,pf,0,0})\n  pf=d'],
  ['rewind forgets the facing', ' pc=h[2] pr=h[3] pf=h[4]', ' pc=h[2] pr=h[3]'],
  ['rewind does not refund', '  act+=1\n else\n  mov+=1', '  act+=0\n else\n  mov+=0'],
  ['you can rotate your own tile', ' local nc,nr=pc+dx[pf],pr+dy[pf]\n if not onb(nc,nr) then return end\n local i=ti(nc,nr)', ' local i=ti(pc,pr)'],
  ['no-op rotations are refunded', ' bd[i]=rotw(bd[i])\n act-=1', ' local w=bd[i]\n bd[i]=rotw(w)\n if bd[i]!=w then act-=1 end'],
  ['only the neighbour wall blocks', '  if (bd[i]&wb[d])>0 then\n   blk=true\n   add(fl,{pc,pr,d})\n  end', ''],
  ['x still works with no movements', ' if act<1 or mov<1 then return end', ' if act<1 then return end'],
  ['win screen ignores rewind', '  elseif btnp(4) then\n   rew()\n  end', '  end'],
  ['out of movements still moves', ' if mov<1 then return end\n add(hs,{0,pc,pr,pf,0,0})', ' add(hs,{0,pc,pr,pf,0,0})'],
];

function main() {
  const cart = fs.readFileSync(path.join(DIR, 'game.p8'), 'utf8');
  const out = path.join(DIR, '_rules.p8');   // distinct name: verify.js uses _test.p8

  build(cart, out);
  const lines = run(out);
  lines.forEach(l => console.log(l));
  const done = lines.find(l => l.startsWith('DONE'));
  if (!done || !/fail=0$/.test(done)) {
    fs.unlinkSync(out);
    console.error('TESTS FAILED');
    process.exit(1);
  }

  if (process.argv.includes('--mutants')) {
    console.log('\nmutation pass:');
    let survivors = 0;
    for (const [name, find, repl] of MUTANTS) {
      if (!cart.includes(find)) {
        console.log('  ?? ' + name + ' - pattern not found in the cart');
        survivors++;
        continue;
      }
      build(cart.replace(find, repl), out);
      const l = run(out);
      const d = l.find(x => x.startsWith('DONE'));
      const killed = !d || !/fail=0$/.test(d);
      console.log('  ' + (killed ? 'killed ' : 'SURVIVED') + ' ' + name +
        (killed && d ? '  (' + d + ')' : ''));
      if (!killed) survivors++;
    }
    if (survivors) {
      fs.unlinkSync(out);
      console.error(survivors + ' mutant(s) survived - the suite has holes');
      process.exit(1);
    }
  }
  fs.unlinkSync(out);
  console.log('\nall good');
}
main();
