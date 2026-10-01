// mutate.js — break one rule at a time and prove the suite notices.
// A green test run means nothing on its own; a mutant that survives is a hole.
//   node mutate.js
'use strict';
const fs = require('fs');
const path = require('path');
const cp = require('child_process');
const d = __dirname;
const P8 = 'C:/Program Files (x86)/PICO-8/pico8.exe';
const SRC = path.join(d, 'code.lua');

const MUTANTS = [
  ['portal only takes one tile', 'add(q,t) co[t]=f', 'co[t]=0'],
  ['portal ownership never recorded', ' pw=f mv+=1', ' mv+=1'],
  ['portal accepts a second pipe', '  if o!=0 then return end', '  if false then return end'],
  ['coverage dropped from the win check', 'if nfil==bw*bh then', 'if ncon==nf then'],
  ['retrace does nothing', ' if #q>1 and q[#q-1]==i then', ' if false then'],
  ['truncation keeps the crossed tile', 'local j=pidx(o,i)', 'local j=pidx(o,i)+1'],
  ['portal back-out ignores direction', 'if ax-px==dx[d] and ay-py==dy[d] then', 'if false then'],
  ['cursor does not follow the teleport', '  cx,cy=cxy(t) return true', '  return true'],
  ['own start dot accepted as the twin', 'if cd[i]!=f or i==q[1] then return end', 'if cd[i]!=f then return end'],
  ['grab does not clear the old path', '  wipe(f)\n  add(fl[f].p,i)', '  add(fl[f].p,i)'],
  ['undo does not pop the stack', "   local f=hs[#hs] or lf", "   local f=lf"],
  ['hold-to-clear never fires', '  if oh==60 then', '  if oh==-1 then'],
  ['cleared bitfield loses bit 15', 'function cld(n) return (cl>>(n-1))&1==1 end',
   'function cld(n) return (cl>>(n-1))%2==1 end'],
  ['unlock gate ignores the previous level', 'function unl(n) return n==1 or cld(n-1) end',
   'function unl(n) return true end'],
  ['connect pulse never armed', 'fl[f].dn=true fl[f].pl=0', 'fl[f].dn=true'],
  ['connect pulse never advances', '   q.pl+=1', '   q.pl+=0'],
  ['lost tail flashes nothing', '   for m=j,#q2 do fx(q2[m],7,2) end', '   for m=j,j-1 do fx(q2[m],7,2) end'],
];

const orig = fs.readFileSync(SRC, 'utf8');
const run = (cmd) => cp.execSync(cmd, { cwd: d, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });

function suite() {
  run('node mk.js');
  run('node mktest.js test');
  // printh lands on stderr on this install, so both streams have to be read
  const r = cp.spawnSync(P8, ['-x', 'test.p8'], { cwd: d, encoding: 'utf8', timeout: 90000 });
  const out = (r.stdout || '') + (r.stderr || '');
  const m = /TESTS (\d+)\/(\d+) passed, (\d+) failed/.exec(out);
  if (!m) return { failed: -1, raw: out.slice(0, 400) };
  return { failed: +m[3], total: +m[2] };
}

let survived = [];
try {
  const base = suite();
  console.log('baseline: ' + base.failed + ' failed of ' + base.total);
  if (base.failed !== 0) throw new Error('baseline is not green — fix that first');

  for (const [name, from, to] of MUTANTS) {
    if (!orig.includes(from)) { console.log('SKIP (no match) ' + name); survived.push(name); continue; }
    fs.writeFileSync(SRC, orig.replace(from, to));
    const r = suite();
    const killed = r.failed > 0;
    console.log((killed ? 'killed  ' : 'SURVIVED') + '  ' + name +
      '  (' + r.failed + ' assertions failed)');
    if (!killed) survived.push(name);
  }
} finally {
  fs.writeFileSync(SRC, orig);
  run('node mk.js');
  run('node mktest.js');
}
console.log(survived.length ? 'HOLES: ' + survived.join(' | ') : 'every mutant killed');
