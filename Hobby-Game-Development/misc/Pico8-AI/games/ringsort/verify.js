// verify.js -- re-measure the level strings that are actually in the cart.
// reads them straight out of game.p8, so it checks the shipped data, not a
// generator artefact. usage: node verify.js [first] [last]
'use strict';
const fs = require('fs');
const S = require('./solver');

const cart = fs.readFileSync('game.p8', 'utf8');
const m = cart.match(/lvs=split\("([^"]+)"/);
if (!m) throw new Error('no lvs= line in game.p8');
const strs = m[1].split(';');

const TARGET = (n) => (n <= 4 ? [4, 12] : n <= 9 ? [12, 22] : n <= 15 ? [24, 38] : [38, 55]);
const first = +(process.argv[2] || 1), last = +(process.argv[3] || strs.length);
const rnd = S.mulberry32(99991);
let bad = 0;

for (let n = first; n <= last; n++) {
  const { state, K, C, pairs } = S.decode(strs[n - 1]);
  const blocked = S.mkBlocked(pairs);
  const dup = strs.indexOf(strs[n - 1]) + 1;

  const notes = [];
  if (S.isSolved(state, K)) notes.push('ALREADY SOLVED');
  for (const p of state) if (S.monoFull(p, K)) notes.push('starts with a finished pillar');
  if (!S.hasMove(state, K, blocked)) notes.push('DEAD ON ARRIVAL');
  if (dup !== n) notes.push('duplicate of L' + dup);
  const counts = {};
  for (const p of state) for (const c of p) counts[c] = (counts[c] || 0) + 1;
  for (let c = 0; c < C; c++) if (counts[c] !== K) notes.push(`colour ${c} has ${counts[c] || 0}/${K} rings`);

  const par = S.bestSolution(state, K, C, blocked, rnd, 6, 1200);
  const [lo, hi] = TARGET(n);
  if (par === null) notes.push('NO SOLUTION FOUND');
  else if (par < lo) notes.push(`par ${par} below target ${lo}`);
  if (notes.length) bad++;
  console.log(
    `L${String(n).padStart(2)} K=${K} C=${C} R=${pairs.length} par=${String(par).padStart(2)} ` +
    `target=${lo}-${hi} ${notes.length ? 'FAIL: ' + notes.join('; ') : 'ok'}`
  );
}
console.log(bad ? `\n${bad} level(s) need attention` : '\nall levels ok');
