// gen-levels.js -- author the 20 ring sort levels offline.
//
// method (design section 4): build the solved state, pick the rule set, then
// random-walk *legal* moves away from it. every state along the walk is
// rule-legal and the reversed walk is a solution, so solvability is guaranteed
// by construction, not by search.
//
// a plain random walk lands close to the solved manifold, so difficulty comes
// from rejection sampling: draw many candidates, screen them with a narrow
// beam, then re-measure the finalists with a wide beam and keep the hardest.
// beam length is an upper bound on optimal; probe.js showed it matching A*
// exactly on 12 of 15 calibration boards, so it is a sound difficulty proxy.
//
// usage: node gen-levels.js [samples] [--exact]
'use strict';
const fs = require('fs');
const S = require('./solver');

const EXACT = process.argv.includes('--exact');
const arg = (k, d) => { const i = process.argv.indexOf(k); return i < 0 ? d : +process.argv[i + 1]; };
// bare first argument = sample count, but only when it really is a number --
// otherwise a leading flag silently becomes NaN and every loop over it is skipped
const SAMPLES = arg('--samples', Number(process.argv[2]) || 260);
const FROM = arg('--from', 1);
const TO = arg('--to', 20);

// ---------------------------------------------------------------- rule shapes

function shuffled(n, rnd) {
  const a = [];
  for (let i = 0; i < n; i++) a.push(i);
  for (let i = n - 1; i > 0; i--) {
    const j = (rnd() * (i + 1)) | 0;
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

const SHAPES = {
  none: () => [],
  // n independent pairs -- two constraints that never interact
  disjoint: (n, c) => {
    const p = [];
    for (let i = 0; i < n; i++) p.push([c[2 * i], c[2 * i + 1]]);
    return p;
  },
  // a path c0-c1-...-cn: the interior colours become hard to park
  chain: (n, c) => {
    const p = [];
    for (let i = 0; i < n; i++) p.push([c[i], c[i + 1]]);
    return p;
  },
  // one colour forbidden against n others: it needs a pillar reserved for it
  hub: (n, c) => {
    const p = [];
    for (let i = 1; i <= n; i++) p.push([c[0], c[i]]);
    return p;
  },
  // hub of 3 with a chain tail hanging off the last leaf
  hubchain: (n, c) => [[c[0], c[1]], [c[0], c[2]], [c[0], c[3]], [c[3], c[4]]],
};

// K rings/pillar, C colours, R rules, shape. free pillars = 8-C.
const SPEC = [
  { K: 2, C: 4, R: 0, shape: 'none' },
  { K: 2, C: 5, R: 0, shape: 'none' },
  { K: 2, C: 6, R: 0, shape: 'none' },
  { K: 2, C: 6, R: 1, shape: 'disjoint' },
  { K: 3, C: 5, R: 1, shape: 'disjoint' },
  { K: 3, C: 6, R: 1, shape: 'disjoint' },
  { K: 3, C: 6, R: 2, shape: 'disjoint' },
  { K: 3, C: 7, R: 1, shape: 'disjoint' },
  { K: 4, C: 5, R: 2, shape: 'disjoint' },
  { K: 4, C: 6, R: 2, shape: 'chain' },
  { K: 4, C: 6, R: 3, shape: 'chain' },
  { K: 4, C: 7, R: 2, shape: 'chain' },
  { K: 4, C: 7, R: 3, shape: 'chain' },
  { K: 5, C: 5, R: 3, shape: 'chain' },
  { K: 5, C: 6, R: 3, shape: 'chain' },
  { K: 5, C: 6, R: 4, shape: 'hubchain' },
  { K: 5, C: 7, R: 3, shape: 'hub' },
  { K: 5, C: 7, R: 4, shape: 'hub' },
  { K: 5, C: 7, R: 4, shape: 'chain' },   // level 19: long chain
  { K: 5, C: 7, R: 4, shape: 'hubchain' },
];

// design section 3 difficulty targets, kept for reporting
const TARGET = (n) => (n <= 4 ? [4, 12] : n <= 9 ? [12, 22] : n <= 15 ? [24, 38] : [38, 55]);

// ---------------------------------------------------------------- shuffling

function solvedState(K, C) {
  const st = [];
  for (let i = 0; i < 8; i++) st.push(i < C ? new Array(K).fill(i) : []);
  return st;
}

function walk(K, C, blocked, steps, rnd) {
  let st = solvedState(K, C);
  let lastSrc = -1, lastDst = -1;
  for (let i = 0; i < steps; i++) {
    // never immediately put the ring back where it came from
    const ms = S.moves(st, K, blocked).filter((m) => !(m[0] === lastDst && m[1] === lastSrc));
    if (ms.length === 0) break;
    const m = ms[(rnd() * ms.length) | 0];
    st = S.apply(st, m);
    lastSrc = m[0]; lastDst = m[1];
  }
  return st;
}

// a start position should not hand the player a finished pillar (design 4.4)
function structurallyOk(st, K, C, blocked) {
  if (S.isSolved(st, K)) return false;
  for (const p of st) if (S.monoFull(p, K)) return false;
  if (!S.hasMove(st, K, blocked)) return false;
  return true;
}

function permutePillars(st, rnd) {
  const idx = shuffled(8, rnd);
  return idx.map((i) => st[i].slice());
}

// ---------------------------------------------------------------- main

const out = [];

// each level gets its own seeded stream, so any sub-range can be regenerated
// on its own and reproduces byte-for-byte -- the 20-level run is resumable.
for (let n = FROM; n <= TO; n++) {
  const rnd = S.mulberry32(20260906 + n * 7919);
  const sp = SPEC[n - 1];
  const { K, C, R } = sp;
  const t0 = Date.now();

  // one rule set for the level, drawn from the colours in play
  let pairs = [];
  if (R > 0) {
    const cols = shuffled(C, rnd);
    pairs = SHAPES[sp.shape](R, cols);
    pairs = pairs.map(([a, b]) => (a < b ? [a, b] : [b, a]));
  }
  const blocked = S.mkBlocked(pairs);

  // screen a wide field of candidates with a narrow beam
  const cands = [];
  for (let i = 0; i < SAMPLES; i++) {
    const steps = 30 + ((rnd() * 520) | 0);
    const st = walk(K, C, blocked, steps, rnd);
    if (!structurallyOk(st, K, C, blocked)) continue;
    const b = S.beam(st, K, C, blocked, 110, 400, rnd);
    if (b === null) continue;
    cands.push([b, st]);
  }
  cands.sort((a, b) => b[0] - a[0]);

  // re-measure the finalists properly -- a narrow beam can overestimate, and we
  // must not mistake "the beam did badly here" for "this board is hard"
  let best = null;
  for (const [, st] of cands.slice(0, 12)) {
    const b = S.bestSolution(st, K, C, blocked, rnd, 4, 900);
    if (b !== null && (best === null || b > best[0])) best = [b, st];
  }
  if (!best) throw new Error('level ' + n + ': no candidate survived');

  let [len, st] = best;
  let exact = null;
  if (EXACT) {
    const a = S.astar(st, K, C, blocked, 250000);
    if (a.optimal !== undefined && a.optimal !== Infinity) { exact = a.optimal; len = a.optimal; }
  }

  const shown = permutePillars(st, rnd);
  const str = S.encode(shown, K, C, pairs);
  const [lo, hi] = TARGET(n);
  out.push({ n, K, C, R, shape: sp.shape, pairs, par: len, exact, target: [lo, hi], str });
  console.log(
    `L${String(n).padStart(2)} K=${K} C=${C} R=${R} ${sp.shape.padEnd(8)} ` +
    `par=${String(len).padStart(2)}${exact !== null ? '*' : ' '} ` +
    `target=${lo}-${hi} ${len >= lo ? 'ok  ' : 'LOW '} ` +
    `(${((Date.now() - t0) / 1000).toFixed(1)}s)  ${str}`
  );

  // appended after every level: a long run is never lost to an interrupt
  fs.appendFileSync('levels.jsonl', JSON.stringify(out[out.length - 1]) + '\n');
}

fs.writeFileSync(`levels-${FROM}-${TO}.json`, JSON.stringify(out, null, 1));
console.log(`\nwrote levels-${FROM}-${TO}.json  (* = proven optimal by A*)`);
