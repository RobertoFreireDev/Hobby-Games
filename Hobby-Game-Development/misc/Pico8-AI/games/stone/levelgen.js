// levelgen.js - build the twelve boards for stone logic (four layers).
//
//   node levelgen.js            search the ladder and write levels.json
//   node levelgen.js report     re-read levels.json and print the proof table
//
// A board is a set of stacks hanging from layer 1 downward: a stack of
// height h fills layers 1..h of one cell, and only its layer-1 stone starts
// face up. Everything deeper is a "?".
//
// The one thing every level has to earn: the faces of the buried stones must
// be *forced*. The player is told the tally (how many of each face are on the
// table, buried ones included) and three or four laws that were true when the
// board was dealt. Exactly one way of filling the buried cells may fit both.
// Each law also has to be load-bearing - drop any one of them and the filling
// stops being unique - so no level ships a law that is decoration.
//
// On top of that the board must be clearable, and at least one legal opening
// must throw the game away, so the deduction is worth doing.
'use strict';
const fs = require('fs'), path = require('path');

// ------------------------------------------------------------------ rng
function mkRng(seed) {
  let s = (seed >>> 0) || 1;
  return () => { s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0; return s / 4294967296; };
}
function shuf(a, r) { for (let i = a.length - 1; i > 0; i--) { const j = (r() * (i + 1)) | 0;[a[i], a[j]] = [a[j], a[i]]; } return a; }

// ------------------------------------------------------------------ shape
// n cells grown into a connected blob inside a 4x4 grid, pushed to origin
function mkShape(n, r) {
  const inb = new Set([(r() * 16) | 0]);
  while (inb.size < n) {
    const cand = [];
    for (const id of inb) {
      const x = id % 4, y = (id / 4) | 0;
      for (const [a, b] of [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]])
        if (a >= 0 && a < 4 && b >= 0 && b < 4 && !inb.has(b * 4 + a)) cand.push(b * 4 + a);
    }
    if (!cand.length) return null;
    inb.add(cand[(r() * cand.length) | 0]);
  }
  let cells = [...inb].map(id => [id % 4, (id / 4) | 0]);
  const cx = Math.min(...cells.map(c => c[0])), cy = Math.min(...cells.map(c => c[1]));
  cells = cells.map(c => [c[0] - cx, c[1] - cy]);
  cells.sort((a, b) => a[1] - b[1] || a[0] - b[0]);
  return cells;
}

function mkHeights(n, total, r) {
  if (total < n || total > 4 * n) return null;
  const h = new Array(n).fill(1);
  let left = total - n, guard = 0;
  while (left > 0 && guard++ < 10000) { const i = (r() * n) | 0; if (h[i] < 4) { h[i]++; left--; } }
  return left ? null : h;
}

function mkBag(total, nf, r) {
  if (total % 2 || total < 2 * nf) return null;
  const faces = shuf([1, 2, 3, 4, 5, 6], r).slice(0, nf);
  const cnt = faces.map(() => 1);                 // pairs, not stones
  let left = total / 2 - nf;
  while (left-- > 0) cnt[(r() * nf) | 0]++;
  const bag = [];
  faces.forEach((f, i) => { for (let k = 0; k < 2 * cnt[i]; k++) bag.push(f); });
  return shuf(bag, r);
}

// ------------------------------------------------------------------ board
// stone ids are flat: off[i]+j is the stone in stack i at layer j+1
function mkBoard(cells, h) {
  const n = cells.length, off = [];
  let m = 0;
  for (let i = 0; i < n; i++) { off.push(m); m += h[i]; }
  const cellOf = new Int32Array(m), layOf = new Int32Array(m);
  for (let i = 0; i < n; i++) for (let j = 0; j < h[i]; j++) { cellOf[off[i] + j] = i; layOf[off[i] + j] = j + 1; }
  const adj = cells.map(() => []);
  for (let i = 0; i < n; i++) for (let k = i + 1; k < n; k++)
    if (Math.abs(cells[i][0] - cells[k][0]) + Math.abs(cells[i][1] - cells[k][1]) === 1) { adj[i].push(k); adj[k].push(i); }
  // two stones touch when one rests on the other, or when they lie side by
  // side in the same layer
  const nb = [];
  for (let id = 0; id < m; id++) {
    const i = cellOf[id], j = layOf[id] - 1, list = [];
    if (j > 0) list.push(off[i] + j - 1);
    if (j < h[i] - 1) list.push(off[i] + j + 1);
    for (const k of adj[i]) if (j < h[k]) list.push(off[k] + j);
    nb.push(list);
  }
  const maxL = Math.max(...h);
  const byLayer = [];
  for (let L = 1; L <= maxL; L++) { const g = []; for (let id = 0; id < m; id++) if (layOf[id] === L) g.push(id); byLayer.push(g); }
  return { cells, h, n, m, off, cellOf, layOf, nb, maxL, byLayer };
}

// ------------------------------------------------------------------ laws
// [kind, a, b] : 2 bond  - every a touches a b
//                3 taboo - no a touches a b (a may equal b)
//                4 depth - no a sits on layer b
function lawHolds(bd, A, law) {
  const [k, a, b] = law;
  for (let id = 0; id < bd.m; id++) {
    if (A[id] !== a && !(k === 3 && A[id] === b)) continue;
    if (k === 4) { if (A[id] === a && bd.layOf[id] === b) return false; continue; }
    const want = A[id] === a ? b : a;
    let near = false;
    for (const o of bd.nb[id]) if (A[o] === want) { near = true; break; }
    if (k === 3 && near) return false;
    if (k === 2 && A[id] === a && !near) return false;
  }
  return true;
}

function lawCandidates(bd, A, faces) {
  const out = [];
  for (const a of faces) for (const b of faces) if (a !== b) out.push([2, a, b]);
  for (const a of faces) for (const b of faces) if (a <= b) out.push([3, a, b]);
  for (const a of faces) for (let L = 2; L <= bd.maxL; L++) out.push([4, a, L]);
  return out.filter(w => lawHolds(bd, A, w));
}

// ------------------------------------------------------------------ deduction
// Count the fillings of the buried cells that fit the tally and every law,
// stopping at `cap`. Buried cells are filled layer by layer, which is what
// makes the pruning exact: once layer L is complete, every stone on layer
// L-1 has all of its neighbours and its bond law can be judged.
function solutions(bd, A, laws, cap, budget) {
  const { m, layOf, nb, maxL, byLayer } = bd;
  const slots = [];
  for (let L = 2; L <= maxL; L++) for (const id of byLayer[L - 1]) slots.push(id);
  if (!slots.length) return 1;

  const need = new Map();
  for (const id of slots) need.set(A[id], (need.get(A[id]) || 0) + 1);
  const faces = [...need.keys()].sort();

  const W = new Int32Array(m);
  for (const id of byLayer[0]) W[id] = A[id];

  const bonds = laws.filter(w => w[0] === 2);
  const taboos = laws.filter(w => w[0] === 3);
  const depths = laws.filter(w => w[0] === 4);
  // slot index at which each layer finishes
  const endOf = new Int32Array(slots.length).fill(-1);
  for (let k = 0; k < slots.length; k++)
    if (k === slots.length - 1 || layOf[slots[k + 1]] !== layOf[slots[k]]) endOf[k] = layOf[slots[k]];

  const bondOk = L => {
    if (!bonds.length || L < 1) return true;
    for (const id of byLayer[L - 1]) for (const w of bonds) {
      if (W[id] !== w[1]) continue;
      let near = false;
      for (const o of nb[id]) if (W[o] === w[2]) { near = true; break; }
      if (!near) return false;
    }
    return true;
  };

  let found = 0, work = 0, blown = false;
  (function rec(k) {
    if (blown) return;
    if (++work > budget) { blown = true; return; }
    if (k === slots.length) { found++; if (found >= cap) blown = true; return; }
    const id = slots[k], L = layOf[id];
    for (const f of faces) {
      if (!need.get(f)) continue;
      let bad = false;
      for (const w of depths) if (f === w[1] && L === w[2]) { bad = true; break; }
      if (!bad) for (const o of nb[id]) {
        const g = W[o];
        if (!g) continue;
        for (const w of taboos) if ((f === w[1] && g === w[2]) || (f === w[2] && g === w[1])) { bad = true; break; }
        if (bad) break;
      }
      if (bad) continue;
      W[id] = f;
      need.set(f, need.get(f) - 1);
      let ok = true;
      if (endOf[k] > 0) {
        ok = bondOk(endOf[k] - 1);
        if (ok && endOf[k] === maxL) ok = bondOk(maxL);
      }
      if (ok) rec(k + 1);
      need.set(f, need.get(f) + 1);
      W[id] = 0;
      if (blown) return;
    }
  })(0);
  return blown && found < cap ? -1 : found;
}

// ------------------------------------------------------------------ play
function winnable(bd, A, rem, memo) {
  let done = true;
  for (let i = 0; i < bd.n; i++) if (rem[i] < bd.h[i]) { done = false; break; }
  if (done) return true;
  const key = rem.join(',');
  const hit = memo.get(key);
  if (hit !== undefined) return hit;
  const tops = [];
  for (let i = 0; i < bd.n; i++) if (rem[i] < bd.h[i]) tops.push(i);
  let ok = false;
  for (let a = 0; a < tops.length && !ok; a++) for (let b = a + 1; b < tops.length && !ok; b++) {
    const i = tops[a], k = tops[b];
    if (A[bd.off[i] + rem[i]] !== A[bd.off[k] + rem[k]]) continue;
    rem[i]++; rem[k]++;
    if (winnable(bd, A, rem, memo)) ok = true;
    rem[i]--; rem[k]--;
  }
  memo.set(key, ok);
  return ok;
}

// every opening pair, split into the ones that keep the board alive and the
// ones that throw it away
function openings(bd, A) {
  const rem = new Array(bd.n).fill(0), memo = new Map();
  const good = [], bad = [];
  for (let i = 0; i < bd.n; i++) for (let k = i + 1; k < bd.n; k++) {
    if (A[bd.off[i]] !== A[bd.off[k]]) continue;
    rem[i]++; rem[k]++;
    (winnable(bd, A, rem, memo) ? good : bad).push([i, k]);
    rem[i]--; rem[k]--;
  }
  return { good, bad };
}

// the order that clears the board, for the record
function solveLine(bd, A) {
  const rem = new Array(bd.n).fill(0), memo = new Map(), line = [];
  const walk = () => {
    let done = true;
    for (let i = 0; i < bd.n; i++) if (rem[i] < bd.h[i]) { done = false; break; }
    if (done) return true;
    for (let i = 0; i < bd.n; i++) for (let k = i + 1; k < bd.n; k++) {
      if (rem[i] >= bd.h[i] || rem[k] >= bd.h[k]) continue;
      if (A[bd.off[i] + rem[i]] !== A[bd.off[k] + rem[k]]) continue;
      rem[i]++; rem[k]++;
      if (winnable(bd, A, rem, memo)) { line.push([i, k]); if (walk()) return true; line.pop(); }
      rem[i]--; rem[k]--;
    }
    return false;
  };
  return walk() ? line : null;
}

// ------------------------------------------------------------------ encode
// four digits a stone - col row layer face - written in solving order
function encode(bd, A, line) {
  const rem = new Array(bd.n).fill(0), out = [];
  const put = i => {
    const id = bd.off[i] + rem[i]++;
    out.push('' + bd.cells[i][0] + bd.cells[i][1] + bd.layOf[id] + A[id]);
  };
  for (const [i, k] of line) { put(i); put(k); }
  return out.join('');
}
const encLaws = laws => laws.map(w => '' + w[0] + w[1] + w[2]).join('');

// ------------------------------------------------------------------ search
const ST = {};
const bump = k => ST[k] = (ST[k] || 0) + 1;

function attempt(spec, seed) {
  const r = mkRng(seed);
  const cells = mkShape(spec.n, r); if (!cells) { bump('shape'); return null; }
  const h = mkHeights(spec.n, spec.total, r); if (!h) { bump('height'); return null; }
  if (Math.max(...h) < spec.deep) { bump('shallow'); return null; }
  const bag = mkBag(spec.total, spec.nf, r); if (!bag) { bump('bag'); return null; }

  const bd = mkBoard(cells, h);
  const A = new Int32Array(bd.m);
  for (let id = 0; id < bd.m; id++) A[id] = bag[id];
  const faces = [...new Set(bag)].sort();

  // a board nobody can clear, or one that cannot be lost, is not a puzzle
  // counting the openings is cheap; proving each one wins or loses is not,
  // so throw the board out on the count before touching the game tree
  let nop = 0;
  for (let i = 0; i < bd.n; i++) for (let k = i + 1; k < bd.n; k++) if (A[bd.off[i]] === A[bd.off[k]]) nop++;
  if (nop < Math.max(spec.traps + 1, spec.minOpen)) { bump('few'); return null; }
  const op = openings(bd, A);
  if (!op.good.length) { bump('dead'); return null; }
  if (op.bad.length < spec.traps) { bump('notrap'); return null; }
  if (op.good.length + op.bad.length < spec.minOpen) { bump('nochoice'); return null; }

  if (solutions(bd, A, [], 2, spec.budget) === 1) { bump('tally'); return null; }

  const cand = shuf(lawCandidates(bd, A, faces), r);
  // depth4 boards must publish a law about the deepest layer, so the "-4"
  // notation the four-layer board added is exercised by a shipped level
  const depth = cand.filter(w => w[0] === 4 && (!spec.depth4 || w[2] === 4));
  const other = cand.filter(w => w[0] !== 4);
  if (!depth.length || other.length < 2) { bump('laws'); return null; }

  const sizes = spec.laws;
  let fallback = null;
  for (let t = 0; t < spec.tries; t++) {
    const k = sizes[(r() * sizes.length) | 0];
    // lead with a depth law, so the "-x" notation stays in play
    const set = [depth[(r() * depth.length) | 0]];
    const pool = shuf(other.concat(depth.filter(w => w !== set[0])), r);
    for (let i = 0; i < pool.length && set.length < k; i++) set.push(pool[i]);
    if (set.length < k) continue;
    const s0 = solutions(bd, A, set, 2, spec.budget);
    if (s0 !== 1) { bump(s0 < 0 ? 'blown' : 'ambig'); continue; }
    // reduce to a set where every law carries weight: drop a law and the
    // filling has to go ambiguous again, or the law was decoration
    let keep = set;
    for (let i = keep.length - 1; i >= 0; i--) {
      const less = keep.filter((_, j) => j !== i);
      if (!less.length) continue;
      if (solutions(bd, A, less, 2, spec.budget) === 1) keep = less;
    }
    if (keep.length < spec.minLaws) { bump('thin'); continue; }
    const line = solveLine(bd, A);
    if (!line) { bump('noline'); continue; }
    // bonds first, then taboos, then depths - the order the ribbon reads in
    keep = keep.slice().sort((x, y) => x[0] - y[0] || x[1] - y[1] || x[2] - y[2]);
    const got = {
      d: encode(bd, A, line), w: encLaws(keep),
      info: {
        seed, stones: bd.m, stacks: bd.n, buried: bd.m - bd.n, faces: faces.length,
        maxL: bd.maxL, laws: keep.length, kinds: keep.map(w => w[0]).join(''),
        openings: op.good.length + op.bad.length, losing: op.bad.length,
        box: [Math.max(...cells.map(c => c[0])) + 1, Math.max(...cells.map(c => c[1])) + 1]
      }
    };
    if (spec.depth4 && !keep.some(w => w[0] === 4 && w[2] === 4)) continue;
    if (keep.some(w => w[0] === 4)) return got;   // prefer a board that uses depth
    fallback = fallback || got;
  }
  if (fallback) return fallback;
  bump('nolaws');
  return null;
}

function search(spec, label) {
  for (let s = spec.seed; s < spec.seed + spec.seeds; s++) {
    const got = attempt(spec, s);
    if (got) { got.info.label = label; return got; }
  }
  throw new Error('no board for ' + label + ' ' + JSON.stringify(ST));
}

// ------------------------------------------------------------------ ladder
// n stacks / total stones. buried = total - n, and that is the number of
// cells the player has to name from the tally and the laws alone.
const base = { deep: 2, traps: 1, laws: [2, 3, 4], minLaws: 1, minOpen: 2, tries: 400, budget: 400000, seeds: 120000 };
const LADDER = [
  { n: 4, total: 6, nf: 3, deep: 2, traps: 0, minOpen: 1, seed: 1001 },
  { n: 5, total: 8, nf: 3, deep: 2, traps: 1, seed: 2001 },
  { n: 5, total: 10, nf: 4, deep: 3, traps: 1, minOpen: 2, seed: 3001 },
  { n: 6, total: 12, nf: 4, deep: 3, traps: 1, seed: 4001 },
  { n: 6, total: 14, nf: 4, deep: 4, traps: 2, seed: 5001 },
  { n: 7, total: 14, nf: 4, deep: 3, traps: 2, seed: 6001 },
  { n: 7, total: 16, nf: 5, deep: 4, traps: 2, seed: 7001 },
  { n: 8, total: 16, nf: 5, deep: 3, traps: 3, seed: 8001 },
  { n: 8, total: 18, nf: 5, deep: 4, traps: 2, minOpen: 3, seed: 9001 },
  { n: 9, total: 20, nf: 5, deep: 4, traps: 2, minOpen: 3, seed: 10001 },
  { n: 11, total: 20, nf: 5, deep: 4, traps: 2, minOpen: 4, depth4: true, seed: 11001 },
  { n: 12, total: 22, nf: 5, deep: 4, traps: 3, minOpen: 4, minLaws: 2, depth4: true, seed: 12001 },
].map(s => ({ ...base, ...s }));

// four lessons. the first two publish no laws - there is nothing to deduce
// yet - so they are written out by hand.
const TUT = [
  { d: '0011101120123012', w: '' },                  // four singles, two pairs
  { d: '001110110112111200231123', w: '' },          // two stacks of two
  { n: 4, total: 8, nf: 3, deep: 2, traps: 0, laws: [1], seed: 21001 },
  { n: 5, total: 10, nf: 3, deep: 3, traps: 1, laws: [2], seed: 22001 },
];

// ------------------------------------------------------------------ main
if (process.argv[2] === 'report') {
  const j = JSON.parse(fs.readFileSync(path.join(__dirname, 'levels.json'), 'utf8'));
  console.log('lvl stones stacks buried faces layers laws opens losing box');
  j.info.forEach((i, k) => console.log(
    String(k + 1).padStart(3), String(i.stones).padStart(6), String(i.stacks).padStart(6),
    String(i.buried).padStart(6), String(i.faces).padStart(5), String(i.maxL).padStart(6),
    String(i.laws).padStart(4), String(i.openings).padStart(5), String(i.losing).padStart(6),
    ' ' + i.box.join('x')));
  process.exit(0);
}

const OUT = path.join(__dirname, 'levels.json');
const out = fs.existsSync(OUT) ? JSON.parse(fs.readFileSync(OUT, 'utf8')) : { lvl: [], lws: [], tut: [], info: [] };
for (const k of ['lvl', 'lws', 'tut', 'info']) out[k] = out[k] || [];
const only = process.argv.slice(2).map(Number).filter(n => n > 0);
const doTut = !only.length || process.argv.indexOf('tut') >= 0;
const onlyTut = !only.length && process.argv.indexOf('tut') >= 0;
const save = () => fs.writeFileSync(OUT, JSON.stringify(out, null, 1) + '\n');
LADDER.forEach((spec, k) => {
  if (onlyTut || (only.length && only.indexOf(k + 1) < 0)) return;
  const g = search(spec, 'level ' + (k + 1));
  out.lvl[k] = g.d; out.lws[k] = g.w; out.info[k] = g.info; save();
  console.log('level ' + (k + 1) + ': ' + g.info.stones + ' stones, ' +
    g.info.buried + ' buried, ' + g.info.laws + ' laws, ' +
    g.info.losing + '/' + g.info.openings + ' openings lose');
});
TUT.forEach((t, k) => {
  if (!doTut) return;
  if (t.d) { out.tut[k] = { d: t.d, w: t.w }; console.log('lesson ' + (k + 1) + ': hand-written'); return; }
  const g = search({ ...base, ...t }, 'lesson ' + (k + 1));
  out.tut[k] = { d: g.d, w: g.w }; save();
  console.log('lesson ' + (k + 1) + ': ' + g.info.stones + ' stones, ' + g.info.buried + ' buried');
});
fs.writeFileSync(path.join(__dirname, 'levels.json'), JSON.stringify(out, null, 1) + '\n');
console.log('levels.json written. rejects: ' + JSON.stringify(ST));
