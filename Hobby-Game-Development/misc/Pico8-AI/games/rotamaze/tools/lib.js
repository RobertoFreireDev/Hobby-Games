// rotamaze - shared model + solver
// board model must match game.p8 exactly:
//   wall bits 1=top 2=right 4=bottom 8=left
//   dir index 0=left 1=right 2=up 3=down  (== pico8 btn index)
'use strict';

const W = 15, H = 14, N = W * H;

const DX = [-1, 1, 0, 0];
const DY = [0, 0, -1, 1];
const WB = [8, 2, 1, 4];   // wall bit on the tile you stand on
const OB = [2, 8, 4, 1];   // wall bit on the neighbour
const OPP = [1, 0, 3, 2];

const rot1 = w => ((w << 1) | (w >> 3)) & 15;
const rotk = (w, k) => { for (let i = 0; i < k; i++) w = rot1(w); return w; };

const col = i => i % W;
const row = i => (i / W) | 0;
const idx = (c, r) => r * W + c;
const nb = (i, d) => {
  const c = col(i) + DX[d], r = row(i) + DY[d];
  if (c < 0 || c >= W || r < 0 || r >= H) return -1;
  return r * W + c;
};
const manh = (a, b) => Math.abs(col(a) - col(b)) + Math.abs(row(a) - row(b));

// can the player step from tile i in direction d?
function passable(board, i, d) {
  const j = nb(i, d);
  if (j < 0) return false;
  if (board[i] & WB[d]) return false;
  if (board[j] & OB[d]) return false;
  return true;
}

// ---------------------------------------------------------------- rng
function rng32(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ---------------------------------------------------- movement search
// state = tile*4 + facing.  moving costs 1 mov, a blocked press
// (which only re-aims) is free.  returns Int16Array dist, -1 = unreached.
function walkDist(board, seeds, movCap) {
  const dist = new Int16Array(N * 4).fill(-1);
  const buckets = [];
  for (let i = 0; i <= movCap; i++) buckets.push([]);
  for (const [s, c] of seeds) {
    if (c > movCap) continue;
    if (dist[s] < 0 || c < dist[s]) { dist[s] = c; buckets[c].push(s); }
  }
  for (let c = 0; c <= movCap; c++) {
    const q = buckets[c];
    for (let qi = 0; qi < q.length; qi++) {
      const s = q[qi];
      if (dist[s] !== c) continue;
      const p = s >> 2;
      for (let d = 0; d < 4; d++) {
        let ns, nc;
        if (passable(board, p, d)) { ns = nb(p, d) * 4 + d; nc = c + 1; }
        else { ns = p * 4 + d; nc = c; }
        if (nc > movCap) continue;
        if (dist[ns] < 0 || nc < dist[ns]) {
          dist[ns] = nc;
          buckets[nc].push(ns);
        }
      }
    }
  }
  return dist;
}

// same walk, but records how each state was reached (for plan replay)
function walkPath(board, seeds, movCap, target) {
  const dist = new Int16Array(N * 4).fill(-1);
  const from = new Int32Array(N * 4).fill(-1);
  const via = new Int8Array(N * 4).fill(-1);
  const buckets = [];
  for (let i = 0; i <= movCap; i++) buckets.push([]);
  for (const [s, c] of seeds) {
    if (c > movCap) continue;
    if (dist[s] < 0 || c < dist[s]) { dist[s] = c; buckets[c].push(s); }
  }
  for (let c = 0; c <= movCap; c++) {
    const q = buckets[c];
    for (let qi = 0; qi < q.length; qi++) {
      const s = q[qi];
      if (dist[s] !== c) continue;
      const p = s >> 2;
      for (let d = 0; d < 4; d++) {
        let ns, nc;
        if (passable(board, p, d)) { ns = nb(p, d) * 4 + d; nc = c + 1; }
        else { ns = p * 4 + d; nc = c; }
        if (nc > movCap) continue;
        if (dist[ns] < 0 || nc < dist[ns]) {
          dist[ns] = nc; from[ns] = s; via[ns] = d;
          buckets[nc].push(ns);
        }
      }
    }
  }
  // walk back from target to whichever seed it came from
  const presses = [];
  let s = target;
  while (from[s] >= 0) { presses.push(via[s]); s = from[s]; }
  presses.reverse();
  return { seed: s, presses, cost: dist[target] };
}

function applyRots(base, rots) {
  const b = Uint8Array.from(base);
  for (const [t, k] of rots) b[t] = rotk(b[t], k);
  return b;
}

const rotsKey = rots => rots.map(([t, k]) => t + ':' + k).join(',');

// -------------------------------------------------------------- solver
// beam search over rotation configurations, one layer per ACT spent.
// every plan it returns is real (it is replayed and checked by verify()).
// returns { best: {act -> mov}, plans: {act -> plan}, near: count }
function solve(base, start, startFace, exitTile, opts = {}) {
  const movCap = opts.movCap ?? 46;
  const actCap = opts.actCap ?? 12;
  const beam = opts.beam ?? 250;
  const succCap = opts.succCap ?? 48;

  const levels = [];
  for (let a = 0; a <= actCap; a++) levels.push(new Map());
  levels[0].set('', {
    rots: [], act: 0, seeds: new Map([[start * 4 + startFace, 0]]),
    origin: new Map(), pri: manh(start, exitTile),
  });

  const best = {}, plans = {}, hits = [];
  let nearCount = 0, nodes = 0;

  for (let a = 0; a <= actCap; a++) {
    const all = [...levels[a].values()];
    all.sort((x, y) => x.pri - y.pri);
    const use = all.slice(0, beam);
    for (const cfg of use) {
      nodes++;
      const board = applyRots(base, cfg.rots);
      cfg.board = board;
      const dist = walkDist(board, cfg.seeds, movCap);
      cfg.dist = dist;
      let ex = -1;
      for (let f = 0; f < 4; f++) {
        const d = dist[exitTile * 4 + f];
        if (d >= 0 && (ex < 0 || d < ex)) ex = d;
      }
      if (ex >= 0) {
        if (best[a] === undefined || ex < best[a]) { best[a] = ex; plans[a] = cfg; }
        hits.push([a, ex]);
        nearCount++;
      }
      if (a === actCap) continue;
      // successors: rotate the tile the player faces, k times, from here
      const cand = [];
      const seen = new Map();               // tile -> min cost + seed states
      for (let s = 0; s < N * 4; s++) {
        const c = dist[s];
        if (c < 0) continue;
        const p = s >> 2, f = s & 3;
        const t = nb(p, f);
        if (t < 0) continue;
        let e = seen.get(t);
        if (!e) { e = { cost: c, seeds: [] }; seen.set(t, e); }
        if (c < e.cost) e.cost = c;
        e.seeds.push([s, c]);
      }
      for (const [t, e] of seen) {
        const w = board[t];
        const done = new Set();
        for (let k = 1; k <= 3 && a + k <= actCap; k++) {
          const w2 = rotk(w, k);
          if (w2 === w || done.has(w2)) continue;
          done.add(w2);
          // only keep rotations that open at least one of t's edges
          let opens = false;
          for (let d = 0; d < 4; d++) {
            const u = nb(t, d);
            if (u < 0) continue;
            const blockedBefore = (w & WB[d]) || (board[u] & OB[d]);
            const blockedAfter = (w2 & WB[d]) || (board[u] & OB[d]);
            if (blockedBefore && !blockedAfter) { opens = true; break; }
          }
          if (!opens) continue;
          cand.push({ t, k, e, pri: e.cost + manh(t, exitTile) });
        }
      }
      cand.sort((x, y) => x.pri - y.pri);
      for (const cd of cand.slice(0, succCap)) {
        const rots = cfg.rots.filter(([tt]) => tt !== cd.t);
        const prev = cfg.rots.find(([tt]) => tt === cd.t);
        const nk = ((prev ? prev[1] : 0) + cd.k) % 4;
        if (nk === 0) continue;               // undoing a full turn is never optimal
        rots.push([cd.t, nk]);
        rots.sort((x, y) => x[0] - y[0]);
        const act = rots.reduce((s, r) => s + r[1], 0);
        if (act > actCap) continue;
        const key = rotsKey(rots);
        const lvl = levels[act];
        let ex2 = lvl.get(key);
        if (!ex2) {
          ex2 = { rots, act, seeds: new Map(), origin: new Map(), pri: 1e9 };
          lvl.set(key, ex2);
        }
        for (const [s, c] of cd.e.seeds) {
          const old = ex2.seeds.get(s);
          if (old === undefined || c < old) {
            ex2.seeds.set(s, c);
            ex2.origin.set(s, { cfg, k: cd.k });
          }
          const pr = c + manh(s >> 2, exitTile);
          if (pr < ex2.pri) ex2.pri = pr;
        }
      }
    }
  }
  return { best, plans, hits, nodes, nearCount };
}

module.exports = {
  W, H, N, DX, DY, WB, OB, OPP, rot1, rotk, col, row, idx, nb, manh,
  passable, rng32, walkDist, walkPath, applyRots, rotsKey, solve,
};
