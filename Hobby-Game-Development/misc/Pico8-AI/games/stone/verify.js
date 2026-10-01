// verify.js - read the boards back out of game.p8 and re-prove them.
//
//   node verify.js [game.p8]
//
// This deliberately shares no code with levelgen.js. It parses the cart's own
// lvl/lws tables, rebuilds each board from the four-digit stones, and checks:
//
//   1  stacks hang from layer 1 with nothing floating, faces pair up
//   2  every published law is true of the dealt board
//   3  filling the buried cells with the tally the player is shown leaves
//      exactly one arrangement that obeys the laws - by brute force, every
//      arrangement of the multiset, full law check at each one, no pruning
//   4  every law is load-bearing: the tally alone leaves more than one
//      filling, and so does dropping any single law
//   5  the recorded order clears the board and never lifts a buried stone
//   6  at least one other opening throws the board away
'use strict';
const fs = require('fs'), path = require('path');

const cart = fs.readFileSync(process.argv[2] || path.join(__dirname, 'game.p8'), 'utf8');
const table = name => {
  const m = cart.match(new RegExp('^' + name + '=\\{([^}]*)\\}', 'm'));
  if (!m) throw new Error('no ' + name + '= table in the cart');
  return [...m[1].matchAll(/"([^"]*)"/g)].map(x => x[1]);
};
const LVL = table('lvl'), LWS = table('lws'), TDAT = table('tdat'), TWL = table('twl');

// ---------------------------------------------------------------- board
function parse(d) {
  const st = [];
  for (let k = 0; k < d.length; k += 4)
    st.push({ c: +d[k], r: +d[k + 1], l: +d[k + 2], f: +d[k + 3] });
  return st;
}
const at = (st, c, r, l) => st.find(t => t.c === c && t.r === r && t.l === l);
const touch = (a, b) => (a.c === b.c && a.r === b.r)
  ? Math.abs(a.l - b.l) === 1
  : a.l === b.l && Math.abs(a.c - b.c) + Math.abs(a.r - b.r) === 1;

function lawHolds(st, w) {
  const [k, x, y] = w;
  for (const t of st) {
    if (k === 4) { if (t.f === x && t.l === y) return false; continue; }
    if (t.f !== x && !(k === 3 && t.f === y)) continue;
    const want = t.f === x ? y : x;
    const near = st.some(o => o !== t && o.f === want && touch(t, o));
    if (k === 3 && near) return false;
    if (k === 2 && t.f === x && !near) return false;
  }
  return true;
}
const lawsHold = (st, ws) => ws.every(w => lawHolds(st, w));

// ---------------------------------------------------------------- 3 + 4
// every arrangement of the buried multiset, checked in full. no pruning, so
// this cannot inherit a mistake from the generator's incremental checks.
function fillings(st, ws, cap) {
  const buried = st.filter(t => at(st, t.c, t.r, t.l - 1));
  const bag = {};
  for (const t of buried) bag[t.f] = (bag[t.f] || 0) + 1;
  const faces = Object.keys(bag).map(Number).sort();
  const keep = buried.map(t => t.f);
  let n = 0;
  (function rec(i) {
    if (n >= cap) return;
    if (i === buried.length) { if (lawsHold(st, ws)) n++; return; }
    for (const f of faces) {
      if (!bag[f]) continue;
      bag[f]--; buried[i].f = f;
      rec(i + 1);
      bag[f]++;
      if (n >= cap) break;
    }
  })(0);
  buried.forEach((t, i) => t.f = keep[i]);
  return n;
}

// ---------------------------------------------------------------- 5 + 6
const tops = st => {
  const m = new Map();
  for (const t of st) {
    const k = t.c + ',' + t.r;
    const cur = m.get(k);
    if (!cur || t.l < cur.l) m.set(k, t);
  }
  return [...m.values()];
};

function winnable(st, memo) {
  if (!st.length) return true;
  const key = st.map(t => '' + t.c + t.r + t.l).sort().join('|');
  const hit = memo.get(key);
  if (hit !== undefined) return hit;
  memo.set(key, false);
  const up = tops(st);
  let ok = false;
  for (let i = 0; i < up.length && !ok; i++) for (let j = i + 1; j < up.length && !ok; j++) {
    if (up[i].f !== up[j].f) continue;
    if (winnable(st.filter(t => t !== up[i] && t !== up[j]), memo)) ok = true;
  }
  memo.set(key, ok);
  return ok;
}

// ---------------------------------------------------------------- run
let bad = 0;
const fail = s => { bad++; console.log('  FAIL ' + s); };
const ck = (c, s) => { if (!c) fail(s); };

function check(name, d, w, want) {
  const st = parse(d);
  const ws = [];
  for (let k = 0; k < w.length; k += 3) ws.push([+w[k], +w[k + 1], +w[k + 2]]);

  ck(st.length % 2 === 0, name + ': odd stone count');
  const cnt = {};
  for (const t of st) cnt[t.f] = (cnt[t.f] || 0) + 1;
  for (const f in cnt) ck(cnt[f] % 2 === 0, name + ': odd count of face ' + f);
  for (const t of st) {
    ck(t.l >= 1 && t.l <= 4, name + ': layer ' + t.l + ' out of range');
    ck(t.c <= 3 && t.r <= 3, name + ': cell outside a 4x4 grid');
    if (t.l > 1) ck(!!at(st, t.c, t.r, t.l - 1), name + ': floating stone');
  }
  const deepest = Math.max(...st.map(t => t.l));
  const buried = st.filter(t => at(st, t.c, t.r, t.l - 1)).length;

  for (const x of ws) ck(lawHolds(st, x), name + ': law ' + x.join('') + ' is false when dealt');

  // a board that publishes laws has to need them. lesson 2 publishes none on
  // purpose - there is nothing to deduce yet - so it is exempt.
  if (buried && ws.length) ck(fillings(st, [], 2) > 1,
    name + ': the tally alone names every buried stone, so the laws are decoration');
  if (ws.length) {
    const n = fillings(st, ws, 2);
    ck(n === 1, name + ': ' + (n > 1 ? 'more than one' : 'no') + ' filling fits the tally and the laws');
    for (let i = 0; i < ws.length; i++) {
      const less = ws.filter((_, j) => j !== i);
      if (!less.length) continue;
      ck(fillings(st, less, 2) > 1, name + ': law ' + ws[i].join('') + ' is decoration');
    }
  }

  // the recorded order
  let live = st.slice();
  for (let k = 0; k < d.length; k += 8) {
    const a = at(live, +d[k], +d[k + 1], +d[k + 2]);
    const b = at(live, +d[k + 4], +d[k + 5], +d[k + 6]);
    if (!a || !b) { fail(name + ': recorded stone already gone at ' + k); return; }
    ck(a.f === b.f, name + ': recorded pair faces differ at ' + k);
    ck(!at(live, a.c, a.r, a.l - 1) && !at(live, b.c, b.r, b.l - 1),
      name + ': recorded pair is buried at ' + k);
    live = live.filter(t => t !== a && t !== b);
  }
  ck(live.length === 0, name + ': ' + live.length + ' stones left over');

  // and how many other openings lose
  const up = tops(st);
  const memo = new Map();
  let good = 0, lost = 0;
  for (let i = 0; i < up.length; i++) for (let j = i + 1; j < up.length; j++) {
    if (up[i].f !== up[j].f) continue;
    (winnable(st.filter(t => t !== up[i] && t !== up[j]), memo) ? good++ : lost++);
  }
  ck(good > 0, name + ': no opening wins');
  if (want) ck(lost >= want, name + ': only ' + lost + ' losing openings, wanted ' + want);
  console.log('  ' + name.padEnd(5) + ' ' + String(st.length).padStart(2) + ' stones, ' +
    String(buried).padStart(2) + ' buried, ' + deepest + ' layers, ' + ws.length + ' laws, ' +
    good + ' openings win / ' + lost + ' lose');
}

console.log('levels');
LVL.forEach((d, i) => check('lv' + (i + 1), d, LWS[i], i >= 2 ? 1 : 0));
console.log('lessons');
TDAT.forEach((d, i) => check('t' + (i + 1), d, TWL[i], 0));
console.log(bad ? bad + ' FAILURES' : 'all boards verified');
process.exit(bad ? 1 : 0);
