// gen-levels.js — generates the gridlock candidate pool on a 6x6 board.
//
// The board is 6x6 with the exit on row 2. A level is 12 pieces: the main
// 2-cell slider plus a mix of 2s and 3s, which puts 25-28 of the 36 cells under
// a piece. At that density almost nothing moves, so most random boards are
// either already solved or dead — the pool comes from a hill climb, not from
// rolling dice.
//
// A move is ONE CELL, not "slide a piece as far as it goes", because that is
// what the cart charges the player for. Par is the exact minimum number of
// those unit slides, and the cart uses par as a hard move budget, so it has to
// be exact: the solver is a full breadth-first walk, not a heuristic search.
// A 6x6 board this dense has few enough reachable states for BFS to finish in
// milliseconds, which the 12x12 version could never afford.
//
// Boards are deduped by encoded string and by cell layout, and scored on how
// much of the answer is real interlock — pieces that must move, pieces parked
// in *their* way, and how often the solution has to come back to a piece it
// already moved — so "shove two blockers out of the lane" boards are dropped
// however long their par.
//
// run: node games/gridlock/gen-levels.js [seconds] [seed]
const fs = require('fs');
const N = 6;            // board is 6x6 cells
const ROW = 2;          // the exit row, and the main piece's row
const NP = 12;          // pieces per board, main one included
const PMIN = 15, PMAX = 25;   // the par window the cart wants
const PERPAR = 60;      // candidates kept per par value
const STATES = 400000;  // BFS ceiling; a board over it is written off
const SECONDS = +process.argv[2] || 120;

let seed = (+process.argv[3] || 0x9e3779b9) | 0;
function rnd(n) {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = seed;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) % n;
}

// ---- board building ----
function grid(ps) {
  const g = new Int8Array(N * N).fill(-1);
  for (let i = 0; i < ps.length; i++) {
    const p = ps[i];
    for (let k = 0; k < p.l; k++) g[(p.y + (p.d ? k : 0)) * N + p.x + (p.d ? 0 : k)] = i;
  }
  return g;
}
function free(g, p) {
  for (let k = 0; k < p.l; k++) {
    const x = p.x + (p.d ? 0 : k), y = p.y + (p.d ? k : 0);
    if (x >= N || y >= N) return false;
    if (g[y * N + x] >= 0) return false;
  }
  return true;
}
// a fresh board: main piece somewhere in the exit row, then pieces dropped at
// random until the count is reached. l=3 is rarer than l=2 — three-cell pieces
// on a 6x6 lock the board solid if there are too many of them.
function make() {
  const ps = [{ x: rnd(3), y: ROW, l: 2, d: 0 }];
  let g = grid(ps);
  for (let t = 0; t < 4000 && ps.length < NP; t++) {
    const d = rnd(2), l = rnd(4) ? 2 : 3;
    const c = { x: rnd(N - (d ? 0 : l - 1)), y: rnd(N - (d ? l - 1 : 0)), l, d };
    if (d === 0 && c.y === ROW) continue;   // no other slider shares the exit row
    if (!free(g, c)) continue;
    ps.push(c);
    g = grid(ps);
  }
  return ps;
}

const key = s => String.fromCharCode.apply(null, s);

// ---- exact BFS over unit slides ----
// A state is one byte per piece: the only coordinate that piece can change.
// Everything else is fixed, so the movable half is all the visited map needs.
function solve(ps) {
  const n = ps.length, L0 = ps[0].l, goalX = N - L0;
  const L = Int8Array.from(ps, p => p.l);
  const D = Int8Array.from(ps, p => p.d);
  const F = Int8Array.from(ps, p => p.d ? p.x : p.y);   // the frozen coordinate
  const st0 = Int8Array.from(ps, p => p.d ? p.y : p.x);
  if (st0[0] === goalX) return null;

  const g = new Int8Array(N * N);
  function fill(st) {
    g.fill(-1);
    for (let i = 0; i < n; i++) {
      const d = D[i], x = d ? F[i] : st[i], y = d ? st[i] : F[i];
      for (let k = 0; k < L[i]; k++) g[(y + (d ? k : 0)) * N + x + (d ? 0 : k)] = i;
    }
  }

  const best = new Map([[key(st0), 0]]);
  let frontier = [st0], depth = 0, goal = null;
  while (frontier.length && !goal) {
    const next = [];
    depth++;
    for (const st of frontier) {
      fill(st);
      for (let i = 0; i < n && !goal; i++) {
        const v = st[i], d = D[i];
        for (let s = -1; s <= 1; s += 2) {
          const e = s < 0 ? v - 1 : v + L[i];
          if (e < 0 || e >= N) continue;
          const ex = d ? F[i] : e, ey = d ? e : F[i];
          if (g[ey * N + ex] !== -1) continue;
          const ns = st.slice();
          ns[i] = v + s;
          const nk = key(ns);
          if (best.has(nk)) continue;
          best.set(nk, depth);
          if (ns[0] === goalX) { goal = ns; break; }
          next.push(ns);
        }
      }
      if (goal) break;
    }
    if (best.size > STATES) return null;
    frontier = next;
  }
  if (!goal) return null;
  const par = depth;

  // no parent pointers: the distance map alone reconstructs the path, by
  // walking back from the goal to any neighbour one step closer to the start
  const path = [];
  let st = goal;
  for (let gc = par; gc > 0; gc--) {
    fill(st);
    let found = false;
    // blockers before the main piece, so the forward path reads as the
    // interleaved solution a player would find rather than "clear the lane,
    // then drive out" — the metrics below are read off this ordering
    for (let z = 1; z <= n && !found; z++) {
      const i = z % n, d = D[i], v = st[i];
      for (let s = -1; s <= 1 && !found; s += 2) {
        const e = s < 0 ? v - 1 : v + L[i];
        if (e < 0 || e >= N) continue;
        const ex = d ? F[i] : e, ey = d ? e : F[i];
        if (g[ey * N + ex] !== -1) continue;
        const ns = st.slice();
        ns[i] = v + s;
        if (best.get(key(ns)) !== gc - 1) continue;
        path.push(i);
        st = ns;
        found = true;
      }
    }
    if (!found) return null;
  }
  return { par, path: path.reverse() };
}

// ---- interlock, read off the starting board alone ----
// req  pieces parked in the lane: every one of them has to move in every
//      solution, so this is a floor no path choice can shift
// req2 pieces sitting in those blockers own escape routes — the second tier of
//      obligations, and what makes a board a knot rather than a queue
function obstruction(ps) {
  const g = grid(ps), m = ps[0];
  const lane = new Set(), second = new Set();
  for (let x = m.x + m.l; x < N; x++) {
    const o = g[ROW * N + x];
    if (o > 0) lane.add(o);
  }
  for (const j of lane) {
    const p = ps[j];
    for (let k = 1; k <= p.y + p.l - ROW; k++) {       // its way up out of the lane
      const y = p.y - k;
      if (y < 0) break;
      const o = g[y * N + p.x];
      if (o >= 0) second.add(o);
    }
    for (let k = 0; k < ROW - p.y + 1; k++) {          // and its way down
      const y = p.y + p.l + k;
      if (y >= N) break;
      const o = g[y * N + p.x];
      if (o >= 0) second.add(o);
    }
  }
  second.delete(0);
  for (const j of lane) second.delete(j);
  return { req: lane.size, req2: second.size };
}

// ---- how much of the board the answer actually uses ----
// mv    distinct pieces the optimal path moves, the main one excluded
// zones how many of the nine 2x2 zones hold a moved piece
// back  how often the path returns to a piece it had already put down
// work  slides that are not the main piece walking its own lane
function metrics(ps, path) {
  const moved = new Set(), zones = new Set();
  let segs = 0, work = 0;
  for (let i = 0; i < path.length; i++) {
    if (i === 0 || path[i] !== path[i - 1]) segs++;
    moved.add(path[i]);
    if (path[i] !== 0) work++;
  }
  moved.delete(0);
  for (const i of moved) {
    const p = ps[i];
    const cx = p.x + (p.d ? 0 : (p.l - 1) / 2), cy = p.y + (p.d ? (p.l - 1) / 2 : 0);
    zones.add(Math.min(2, cy / 2 | 0) * 3 + Math.min(2, cx / 2 | 0));
  }
  const o = obstruction(ps);
  return { mv: moved.size, zones: zones.size, back: segs - moved.size - 1, work, req: o.req, req2: o.req2 };
}

const enc = ps => ps.map(p => p.x + '' + p.y + p.l + p.d).join('');
function mask(ps) {
  const m = new Uint8Array(N * N);
  for (const p of ps)
    for (let k = 0; k < p.l; k++) m[(p.y + (p.d ? k : 0)) * N + p.x + (p.d ? 0 : k)] = 1;
  return m;
}
function diff(a, b) {
  let d = 0;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) d++;
  return d;
}
const MINDIFF = 6;   // at least 6 of 36 cells must differ from every kept board

// ---- the search ----
function score(par, m) {
  return par * 4 + m.req * 5 + m.req2 * 4 + m.mv * 3 + m.zones * 4 + m.back * 4;
}

// one edit: relocate/reshape a piece, or slide the main piece start. The
// piece count never changes — every level ships exactly NP pieces.
function mutate(ps) {
  const q = ps.map(p => ({ ...p }));
  if (rnd(14) === 0) {
    const g = grid(q);
    const m = q[0];
    for (let k = 0; k < m.l; k++) g[ROW * N + m.x + k] = -1;
    for (let t = 0; t < 20; t++) {
      const x = rnd(N - m.l + 1);
      if (free(g, { x, y: ROW, l: m.l, d: 0 })) { m.x = x; return q; }
    }
    return q;
  }
  const i = 1 + rnd(q.length - 1);
  const g = grid(q);
  for (let k = 0; k < q[i].l; k++)
    g[(q[i].y + (q[i].d ? k : 0)) * N + q[i].x + (q[i].d ? 0 : k)] = -1;
  for (let t = 0; t < 60; t++) {
    const d = rnd(2), l = rnd(4) ? 2 : 3;
    const c = { x: rnd(N - (d ? 0 : l - 1)), y: rnd(N - (d ? l - 1 : 0)), l, d };
    if (d === 0 && c.y === ROW) continue;
    if (free(g, c)) { q[i] = c; return q; }
  }
  return ps.map(p => ({ ...p }));
}

const byPar = new Map();
const seen = new Set();
const masks = [];
const t0 = Date.now();
let tried = 0, kept = 0, dull = 0, dup = 0, dead = 0, restarts = 0;

function offer(ps, par, m) {
  if (par < PMIN || par > PMAX) return;
  if (m.mv < 5 || m.zones < 5 || m.back < 2 || m.req < 2 || m.req2 < 2) { dull++; return; }
  const b = byPar.get(par) || [];
  if (b.length >= PERPAR) return;
  const code = enc(ps);
  if (seen.has(code)) { dup++; return; }
  const mk = mask(ps);
  for (const q of masks) if (diff(mk, q) < MINDIFF) { dup++; return; }
  seen.add(code);
  masks.push(mk);
  kept++;
  if (!byPar.has(par)) byPar.set(par, b);
  b.push({ par, code, np: ps.length, mv: m.mv, zones: m.zones, back: m.back, work: m.work, req: m.req, req2: m.req2 });
}

const elite = [];
function remember(ps, s) {
  elite.push({ ps: ps.map(p => ({ ...p })), s });
  if (elite.length > 60) {
    elite.sort((a, b) => b.s - a.s);
    elite.length = 40;
  }
}

let cur = null, curS = -1, stale = 0;
while (Date.now() - t0 < SECONDS * 1000) {
  let ps;
  if (!cur || stale > 60) {
    if (elite.length > 10 && rnd(2)) {
      const e = elite[rnd(elite.length)];
      ps = mutate(e.ps);
      cur = null; curS = e.s - 6; stale = 0;
    } else {
      ps = make();
      if (ps.length < NP) continue;
      cur = null; curS = -1; stale = 0;
    }
    restarts++;
  } else {
    ps = mutate(cur);
  }
  tried++;
  const r = solve(ps);
  if (!r) { dead++; stale++; continue; }
  const m = metrics(ps, r.path);
  offer(ps, r.par, m);
  const s = score(r.par, m);
  if (s > curS) { cur = ps; curS = s; stale = 0; remember(ps, s); }
  else if (s >= curS - 2) { cur = ps; curS = s; stale++; }
  else stale++;
}

const out = [...byPar.values()].flat();
fs.writeFileSync(__dirname + '/candidates' + (process.argv[3] ? '-' + (process.argv[3]|0) : '') + '.json', JSON.stringify(out));
const pars = [...byPar.keys()].sort((a, b) => a - b);
console.log('solved', tried, 'kept', kept, 'too dull', dull, 'near-dupes', dup,
  'unsolvable', dead, 'climbs', restarts, 'in', ((Date.now() - t0) / 1000) | 0, 's');
console.log('unique codes:', new Set(out.map(e => e.code)).size, 'of', out.length);
console.log('pars available:', pars.map(p => p + 'x' + byPar.get(p).length).join(' '));
