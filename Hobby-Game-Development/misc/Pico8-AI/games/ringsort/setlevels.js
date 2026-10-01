// setlevels.js -- splice generated level strings into game.p8's lvs= line.
//
//   node setlevels.js levels.jsonl [more.jsonl ...]
//
// Each jsonl record is {n, str, par, ...} as written by gen-levels.js. Records
// for the same level overwrite earlier ones, so re-running a single level and
// passing its file last is how you replace one entry. Levels not covered by any
// record keep whatever is already in the cart.
'use strict';
const fs = require('fs');

const cart = fs.readFileSync('game.p8', 'utf8');
const m = cart.match(/lvs=split\("([^"]+)"/);
if (!m) throw new Error('no lvs= line in game.p8');
const strs = m[1].split(';');
if (strs.length !== 20) throw new Error('expected 20 levels, found ' + strs.length);

const pars = {};
let n_set = 0;
for (const f of process.argv.slice(2)) {
  for (const line of fs.readFileSync(f, 'utf8').split('\n')) {
    if (!line.trim()) continue;
    const r = JSON.parse(line);
    if (!(r.n >= 1 && r.n <= 20)) throw new Error('bad level number ' + r.n);
    strs[r.n - 1] = r.str;
    pars[r.n] = r.par;
    n_set++;
  }
}

if (strs.some((s) => !/^\d\|\d\|\d*\|[0-6,-]+$/.test(s))) throw new Error('malformed level string');
const dupes = strs.filter((s, i) => strs.indexOf(s) !== i);
if (dupes.length) console.log('WARNING: duplicate level strings still present:\n  ' + dupes.join('\n  '));

fs.writeFileSync('game.p8', cart.replace(m[1], strs.join(';')));
console.log(`spliced ${n_set} level(s) into game.p8`);
for (const n of Object.keys(pars).sort((a, b) => a - b)) console.log(`  L${n} par=${pars[n]}  ${strs[n - 1]}`);
