// solver.js -- ring sort rules + solvers (offline authoring tool, not shipped)
//
// state = array of 8 arrays, each array is one pillar bottom->top, values are
// colour indices 0..C-1. pillars are positionally interchangeable, so every
// lookup is keyed on the *sorted* pillar list -- that symmetry collapse is what
// makes exact search possible at all on the small levels.
'use strict';

const NP = 8; // pillars, always 8

// ---------------------------------------------------------------- rules

// blocked is a flat 8*8 Uint8Array, blocked[a*8+b] == 1 means {a,b} forbidden.
function mkBlocked(pairs) {
  const b = new Uint8Array(64);
  for (const [x, y] of pairs) { b[x * 8 + y] = 1; b[y * 8 + x] = 1; }
  return b;
}

function canPlace(state, colour, dst, K, blocked) {
  const p = state[dst];
  if (p.length >= K) return false;
  if (p.length === 0) return true;
  return blocked[colour * 8 + p[p.length - 1]] === 0;
}

// win: every non-empty pillar is monochrome AND full. with exactly K rings per
// colour that is the same as "each colour lives in exactly one pillar".
function isSolved(state, K) {
  for (let i = 0; i < NP; i++) {
    const p = state[i];
    if (p.length === 0) continue;
    if (p.length !== K) return false;
    for (let j = 1; j < p.length; j++) if (p[j] !== p[0]) return false;
  }
  return true;
}

function monoFull(p, K) {
  if (p.length !== K) return false;
  for (let j = 1; j < p.length; j++) if (p[j] !== p[0]) return false;
  return true;
}

// canonical key: pillar contents sorted, so permutations collapse to one entry.
function key(state) {
  const a = new Array(NP);
  for (let i = 0; i < NP; i++) a[i] = state[i].join('');
  a.sort();
  return a.join('|');
}

function clone(state) {
  const s = new Array(NP);
  for (let i = 0; i < NP; i++) s[i] = state[i].slice();
  return s;
}

// legal moves as [src,dst] pairs. duplicate source pillars and duplicate
// destination pillars are collapsed -- both are pure symmetry, so this is safe
// for optimality (the resulting states are permutations of each other).
function moves(state, K, blocked) {
  const out = [];
  const seenSrc = new Set();
  for (let s = 0; s < NP; s++) {
    const sp = state[s];
    if (sp.length === 0) continue;
    const ks = sp.join('');
    if (seenSrc.has(ks)) continue;
    seenSrc.add(ks);
    const c = sp[sp.length - 1];
    const seenDst = new Set();
    for (let d = 0; d < NP; d++) {
      if (d === s) continue;
      if (!canPlace(state, c, d, K, blocked)) continue;
      const kd = state[d].join('');
      if (seenDst.has(kd)) continue;
      seenDst.add(kd);
      out.push([s, d]);
    }
  }
  return out;
}

// any legal move at all that is not "shuffling a finished pillar"? this is the
// exact predicate the cart uses for dead-state detection (design section 7).
function hasMove(state, K, blocked) {
  for (let s = 0; s < NP; s++) {
    const sp = state[s];
    if (sp.length === 0) continue;
    if (monoFull(sp, K)) continue;
    const c = sp[sp.length - 1];
    for (let d = 0; d < NP; d++) {
      if (d === s) continue;
      if (canPlace(state, c, d, K, blocked)) return true;
    }
  }
  return false;
}

function apply(state, m) {
  const s = clone(state);
  s[m[1]].push(s[m[0]].pop());
  return s;
}

// ---------------------------------------------------------------- heuristic

// admissible lower bound on remaining moves.
//
// a ring that is never moved must have every ring below it never moved too (you
// cannot slide one underneath). so the never-moved rings of a pillar are a
// bottom prefix, and since that pillar ends monochrome the prefix is the
// pillar's bottom monochrome run. each colour finishes in exactly one pillar, so
// at most one pillar's run counts per colour. everything else moves >= once.
function heur(state, K, C) {
  const best = new Array(C).fill(0);
  for (let i = 0; i < NP; i++) {
    const p = state[i];
    if (p.length === 0) continue;
    const c = p[0];
    let n = 1;
    while (n < p.length && p[n] === c) n++;
    if (n > best[c]) best[c] = n;
  }
  let stay = 0;
  for (let c = 0; c < C; c++) stay += best[c];
  return C * K - stay;
}

// ---------------------------------------------------------------- A*

// A* with the admissible heuristic above. h is admissible, so if this returns a
// solution it is a *proven optimal* length. if it runs out of budget it returns
// the highest f-value it fully expanded, which is a certified lower bound:
// optimal > lb.
//
// returns {optimal:n} | {lb:n, exhausted:true}
function astar(start, K, C, blocked, maxNodes) {
  if (isSolved(start, K)) return { optimal: 0 };
  const h0 = heur(start, K, C);
  const buckets = [];           // buckets[f] = array of states
  const g = new Map();          // key -> best g seen
  const push = (st, gv, f) => {
    while (buckets.length <= f) buckets.push(null);
    if (!buckets[f]) buckets[f] = [];
    buckets[f].push([st, gv]);
  };
  push(start, 0, h0);
  g.set(key(start), 0);
  let nodes = 0;
  let f = h0;
  let lastFullF = h0 - 1;
  while (f < buckets.length) {
    const b = buckets[f];
    if (!b || b.length === 0) { lastFullF = f; f++; continue; }
    const [st, gv] = b.pop();
    const k = key(st);
    if (g.get(k) < gv) continue;
    nodes++;
    if (nodes > maxNodes) return { lb: lastFullF, exhausted: true, nodes };
    for (const m of moves(st, K, blocked)) {
      const ns = apply(st, m);
      const ng = gv + 1;
      const nk = key(ns);
      const old = g.get(nk);
      if (old !== undefined && old <= ng) continue;
      g.set(nk, ng);
      if (isSolved(ns, K)) return { optimal: ng, nodes };
      push(ns, ng, ng + heur(ns, K, C));
    }
  }
  return { optimal: Infinity, nodes }; // exhausted the space: unsolvable
}

// ---------------------------------------------------------------- beam

// beam search: cheap upper bound on the optimal length for states A* cannot
// finish. returns a solution length or null.
// beam search. only the states that actually survive the width cut are marked
// seen -- marking every generated state (including the ones pruned away) lets
// a wide beam strangle itself: at some depth every successor has already been
// discarded by an earlier layer, next comes back empty, and the run reports
// "unsolvable" for a board that is solvable by construction.
function beam(start, K, C, blocked, width, maxDepth, rnd) {
  if (isSolved(start, K)) return 0;
  let frontier = [start];
  const seen = new Set([key(start)]);
  for (let depth = 1; depth <= maxDepth; depth++) {
    const next = [];
    const here = new Set();
    for (const st of frontier) {
      for (const m of moves(st, K, blocked)) {
        const ns = apply(st, m);
        const nk = key(ns);
        if (seen.has(nk) || here.has(nk)) continue;
        here.add(nk);
        if (isSolved(ns, K)) return depth;
        next.push([heur(ns, K, C) + rnd() * 1.6, ns, nk]);
      }
    }
    if (next.length === 0) return null;
    next.sort((a, b) => a[0] - b[0]);
    const keep = next.slice(0, width);
    for (const x of keep) seen.add(x[2]);
    frontier = keep.map((x) => x[1]);
  }
  return null;
}

// best upper bound over several randomised beam runs.
function bestSolution(start, K, C, blocked, rnd, runs, width) {
  let best = null;
  for (let i = 0; i < runs; i++) {
    let r = beam(start, K, C, blocked, width, 400, rnd);
    // a failed run means the beam lost the thread, not that the board is
    // unsolvable -- narrower beams follow the heuristic more greedily and
    // usually still find *a* solution, which is all an upper bound needs
    for (let w = width; r === null && w > 40; w = (w / 4) | 0) {
      r = beam(start, K, C, blocked, w, 400, rnd);
    }
    if (r !== null && (best === null || r < best)) best = r;
  }
  return best;
}

// ---------------------------------------------------------------- rng

function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ---------------------------------------------------------------- serialise

const DIG = '0123456789abcdef';

function encode(state, K, C, pairs) {
  const rules = pairs.map(([a, b]) => DIG[a] + DIG[b]).join('');
  const ps = state.map((p) => (p.length === 0 ? '-' : p.map((c) => DIG[c]).join('')));
  return K + '|' + C + '|' + rules + '|' + ps.join(',');
}

function decode(s) {
  const [ks, cs, rules, ps] = s.split('|');
  const K = +ks, C = +cs;
  const pairs = [];
  for (let i = 0; i < rules.length; i += 2) {
    pairs.push([parseInt(rules[i], 16), parseInt(rules[i + 1], 16)]);
  }
  const state = ps.split(',').map((p) => (p === '-' ? [] : p.split('').map((c) => parseInt(c, 16))));
  return { K, C, pairs, state, blocked: mkBlocked(pairs) };
}

module.exports = {
  NP, mkBlocked, canPlace, isSolved, monoFull, key, clone, moves, hasMove,
  apply, heur, astar, beam, bestSolution, mulberry32, encode, decode,
};
