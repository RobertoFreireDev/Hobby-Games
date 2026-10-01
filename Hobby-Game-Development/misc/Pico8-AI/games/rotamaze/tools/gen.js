// rotamaze - build and verify the 64-maze pool.
//   node gen.js [tries] [outfile]
// generates candidates, solves each with the beam solver, replays the
// solution through a port of the cart's rules, and keeps 64 that pass.
'use strict';
const fs = require('fs');
const L = require('./lib.js');
const P = require('./plan.js');

const MOVCAP = 42, ACTCAP = 12;

function shuffle(a, rng) {
  for (let i = a.length - 1; i > 0; i--) {
    const j = (rng() * (i + 1)) | 0;
    [a[i], a[j]] = [a[j], a[i]];
  }
}

// tile-level BFS over open edges (no facing, no rotations)
function routeExists(open, s, e) {
  const seen = new Uint8Array(L.N), q = [s], from = new Int32Array(L.N).fill(-1);
  seen[s] = 1;
  for (let qi = 0; qi < q.length; qi++) {
    const i = q[qi];
    if (i === e) {
      const path = [];
      for (let k = e; from[k] >= 0; k = from[k]) path.push([from[k], k]);
      return path;
    }
    for (let d = 0; d < 4; d++) {
      if (!open[i][d]) continue;
      const j = L.nb(i, d);
      if (j < 0 || seen[j]) continue;
      seen[j] = 1; from[j] = i; q.push(j);
    }
  }
  return null;
}

function candidate(rng, p) {
  // 1. perfect maze (dfs backtracker) over the whole grid
  const open = Array.from({ length: L.N }, () => [false, false, false, false]);
  const link = (i, d) => { open[i][d] = true; open[L.nb(i, d)][L.OPP[d]] = true; };
  const cut = (i, d) => { open[i][d] = false; open[L.nb(i, d)][L.OPP[d]] = false; };
  const vis = new Uint8Array(L.N);
  const st = [(rng() * L.N) | 0];
  vis[st[0]] = 1;
  while (st.length) {
    const i = st[st.length - 1];
    const opts = [];
    for (let d = 0; d < 4; d++) {
      const j = L.nb(i, d);
      if (j >= 0 && !vis[j]) opts.push(d);
    }
    if (!opts.length) { st.pop(); continue; }
    const d = opts[(rng() * opts.length) | 0];
    const j = L.nb(i, d);
    link(i, d); vis[j] = 1; st.push(j);
  }
  // 2. braid - open some walls back up so the maze has loops and decoys
  for (let i = 0; i < L.N; i++) for (const d of [1, 3]) {
    if (L.nb(i, d) < 0 || open[i][d]) continue;
    if (rng() < p.braid) link(i, d);
  }
  // 3. start / exit, far apart
  let s, e, guard = 0;
  do {
    s = (rng() * L.N) | 0; e = (rng() * L.N) | 0;
  } while (L.manh(s, e) < 18 && guard++ < 500);
  if (L.manh(s, e) < 18) return null;

  // 4. close the route down: cut edges on the current best path until
  //    start and exit are disconnected, then scatter a few more cuts.
  let gates = 0;
  for (let k = 0; k < 24; k++) {
    const path = routeExists(open, s, e);
    if (!path) break;
    const [a, b] = path[(rng() * path.length) | 0];
    for (let d = 0; d < 4; d++) if (L.nb(a, d) === b) cut(a, d);
    gates++;
  }
  if (routeExists(open, s, e)) return null;
  const openEdges = [];
  for (let i = 0; i < L.N; i++) for (const d of [1, 3]) {
    if (L.nb(i, d) >= 0 && open[i][d]) openEdges.push([i, d]);
  }
  shuffle(openEdges, rng);
  for (let k = 0; k < p.extra && k < openEdges.length; k++) cut(openEdges[k][0], openEdges[k][1]);

  // 5. hand each closed edge to one tile, both tiles (a thick wall), or
  //    neither is not an option - the edge has to block.
  const board = new Uint8Array(L.N);
  for (let i = 0; i < L.N; i++) for (const d of [1, 3]) {
    const j = L.nb(i, d);
    if (j < 0 || open[i][d]) continue;
    const r = rng();
    if (r < p.thick) { board[i] |= L.WB[d]; board[j] |= L.OB[d]; }
    else if (r < p.thick + (1 - p.thick) / 2) board[i] |= L.WB[d];
    else board[j] |= L.OB[d];
  }
  return { board, start: s, exit: e, face: (rng() * 4) | 0, gates };
}

function tierOf(a) {
  if (a <= 2) return 0;
  if (a <= 6) return 1;
  if (a <= 9) return 2;
  return 3;
}
const SLACK = [[3, 2], [2, 1], [1, 1], [0, 0]];   // [mov, act] per tier
// how many distinct near-optimal routes a tier must admit. the hard tiers
// are meant to be near-unique (design 11), so the bar drops as they get harder.
const NEAR_MIN = [3, 3, 2, 1];
const TIER_NAMES = ['warm-up', 'standard', 'hard', 'brutal'];
const TIER_WANT = [8, 32, 16, 8];

function evaluate(c, beam) {
  const r = L.solve(c.board, c.start, c.face, c.exit,
    { movCap: MOVCAP, actCap: ACTCAP, beam, succCap: 40 });
  if (r.best[0] !== undefined) return { reject: 'zero-rotation solution' };
  let A = -1, score = 1e9;
  for (let a = 1; a <= ACTCAP; a++) {
    const m = r.best[a];
    if (m === undefined) continue;
    if (m + a < score) { score = m + a; A = a; }
  }
  if (A < 0) return { reject: 'unsolvable in budget' };
  const M = r.best[A];
  if (M < 18) return { reject: 'route too short (' + M + ')' };
  // how many other near-optimal routes are there?
  const near = r.hits.filter(h => h[0] <= A + 1 && h[1] <= M + 2).length;
  return { A, M, near, res: r };
}

function main() {
  const tries = parseInt(process.argv[2] || '4000', 10);
  const out = process.argv[3] || 'mazes.json';
  const rng = L.rng32(20260826);
  const pool = [[], [], [], []];
  const rejects = {};
  let made = 0;

  for (let t = 0; t < tries; t++) {
    if (pool.every((p, i) => p.length >= TIER_WANT[i])) break;
    const p = {
      braid: 0.02 + rng() * 0.16,
      extra: (rng() * 24) | 0,
      thick: 0.06 + rng() * 0.16,
    };
    const c = candidate(rng, p);
    if (!c) { rejects.degenerate = (rejects.degenerate || 0) + 1; continue; }
    made++;
    const q = evaluate(c, 90);                 // cheap screening pass
    if (q.reject) { rejects[q.reject] = (rejects[q.reject] || 0) + 1; continue; }
    const tier = tierOf(q.A);
    if (pool[tier].length >= TIER_WANT[tier]) continue;
    const g = evaluate(c, 400);                // careful pass on a finalist
    if (g.reject) { rejects[g.reject] = (rejects[g.reject] || 0) + 1; continue; }
    if (g.near < NEAR_MIN[tierOf(g.A)]) { rejects['too few routes'] = (rejects['too few routes'] || 0) + 1; continue; }
    const tier2 = tierOf(g.A);
    if (pool[tier2].length >= TIER_WANT[tier2]) continue;
    const [sm, sa] = SLACK[tier2];
    const maze = {
      board: [...c.board], start: c.start, exit: c.exit, face: c.face,
      movBudget: Math.min(40, g.M + sm), actBudget: g.A + sa,
      movOpt: g.M, actOpt: g.A, near: g.near, tier: tier2, params: p,
    };
    // verify: rebuild the solver's plan and replay it through the cart rules
    const presses = P.planPresses(g.res.plans[g.A], c.exit, MOVCAP);
    if (!presses) { rejects['no plan'] = (rejects['no plan'] || 0) + 1; continue; }
    const rp = P.replay(maze, presses);
    if (!rp.ok || rp.moved !== g.M || rp.rots !== g.A) {
      rejects['replay mismatch'] = (rejects['replay mismatch'] || 0) + 1;
      continue;
    }
    maze.plan = presses.slice(0, rp.used);   // drop any free turns after the win
    pool[tier2].push(maze);
  }

  const mazes = [];
  for (let t = 0; t < 4; t++) for (const m of pool[t]) mazes.push(m);
  console.log('candidates built:', made);
  console.log('rejects:', rejects);
  for (let t = 0; t < 4; t++) {
    const p = pool[t];
    console.log(TIER_NAMES[t].padEnd(9), p.length + '/' + TIER_WANT[t],
      p.length ? 'mov ' + Math.min(...p.map(m => m.movBudget)) + '-' + Math.max(...p.map(m => m.movBudget)) +
      '  act ' + Math.min(...p.map(m => m.actBudget)) + '-' + Math.max(...p.map(m => m.actBudget)) : '');
  }
  console.log('total:', mazes.length);
  if (mazes.length === 64) {
    shuffle(mazes, rng);                       // pool order carries no tier signal
    fs.writeFileSync(out, JSON.stringify(mazes));
    console.log('wrote', out);
  } else {
    console.log('NOT WRITTEN - need exactly 64');
  }
}
module.exports = { candidate, evaluate, tierOf, SLACK, TIER_WANT, TIER_NAMES, MOVCAP, ACTCAP, shuffle };
if (require.main === module) main();
