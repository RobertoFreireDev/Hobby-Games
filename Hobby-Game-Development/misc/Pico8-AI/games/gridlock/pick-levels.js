// pick-levels.js — turns the candidate pool into the cart's 12-level ladder.
//
// Reads every candidates*.json the generator wrote, lays out a par ramp from 15
// to 25, and for each rung picks the board that looks *least* like the ones
// already chosen: with only twelve levels there is no room for two boards a
// player would mistake for each other, so distinctness outranks raw score and
// only breaks ties by quality. Every pick is re-solved from its encoded string
// with an independent BFS, so the par written into the cart is verified against
// the exact same data the cart will parse — a mis-stated par is fatal there,
// since par doubles as the move budget.
//
// run: node games/gridlock/pick-levels.js
const fs = require('fs');
const N = 6, ROW = 2;

// the ladder: 12 rungs climbing 15 -> 25 unit slides, the last one a repeat of
// the top par so the finale is a second hardest rather than a step down
const RAMP = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 25];

const pool = [];
for (const f of fs.readdirSync(__dirname))
  if (/^candidates.*\.json$/.test(f)) pool.push(...JSON.parse(fs.readFileSync(__dirname + '/' + f, 'utf8')));

const dec = code => {
  const ps = [];
  for (let i = 0; i < code.length; i += 4)
    ps.push({ x: +code[i], y: +code[i + 1], l: +code[i + 2], d: +code[i + 3] });
  return ps;
};

// ---- independent verifier: exact BFS, same rules as the cart ----
const key = s => String.fromCharCode.apply(null, s);
function par(ps) {
  const n = ps.length, L0 = ps[0].l, goalX = N - L0;
  const L = Int8Array.from(ps, p => p.l);
  const D = Int8Array.from(ps, p => p.d);
  const F = Int8Array.from(ps, p => p.d ? p.x : p.y);
  const st0 = Int8Array.from(ps, p => p.d ? p.y : p.x);
  const g = new Int8Array(N * N);
  const fill = st => {
    g.fill(-1);
    for (let i = 0; i < n; i++) {
      const d = D[i], x = d ? F[i] : st[i], y = d ? st[i] : F[i];
      for (let k = 0; k < L[i]; k++) g[(y + (d ? k : 0)) * N + x + (d ? 0 : k)] = i;
    }
  };
  if (st0[0] === goalX) return 0;
  const seen = new Set([key(st0)]);
  let frontier = [st0], depth = 0;
  while (frontier.length) {
    const next = [];
    depth++;
    for (const st of frontier) {
      fill(st);
      for (let i = 0; i < n; i++) {
        const v = st[i], d = D[i];
        for (let s = -1; s <= 1; s += 2) {
          const e = s < 0 ? v - 1 : v + L[i];
          if (e < 0 || e >= N) continue;
          const ex = d ? F[i] : e, ey = d ? e : F[i];
          if (g[ey * N + ex] !== -1) continue;
          const ns = st.slice();
          ns[i] = v + s;
          const nk = key(ns);
          if (seen.has(nk)) continue;
          seen.add(nk);
          if (ns[0] === goalX) return depth;
          next.push(ns);
        }
      }
    }
    frontier = next;
  }
  return -1;
}

// ---- structural sanity, independent of the solver ----
function legal(ps) {
  if (ps.length !== 12) return 'wrong piece count';
  const g = new Int8Array(N * N).fill(-1);
  for (let i = 0; i < ps.length; i++) {
    const p = ps[i];
    if (p.l < 2 || p.l > 3 || p.d > 1) return 'bad shape';
    for (let k = 0; k < p.l; k++) {
      const x = p.x + (p.d ? 0 : k), y = p.y + (p.d ? k : 0);
      if (x >= N || y >= N || x < 0 || y < 0) return 'off board';
      if (g[y * N + x] >= 0) return 'overlap';
      g[y * N + x] = i;
    }
  }
  if (ps[0].d !== 0 || ps[0].y !== ROW || ps[0].l !== 2) return 'bad main piece';
  for (let i = 1; i < ps.length; i++)
    if (ps[i].d === 0 && ps[i].y === ROW) return 'slider in the exit row';
  return null;
}

const score = e => e.par * 4 + e.req * 5 + e.req2 * 4 + e.mv * 3 + e.zones * 4 + e.back * 4;
function mask(ps) {
  const m = new Uint8Array(N * N);
  for (const p of ps)
    for (let k = 0; k < p.l; k++) m[(p.y + (p.d ? k : 0)) * N + p.x + (p.d ? 0 : k)] = 1;
  return m;
}
const diff = (a, b) => { let d = 0; for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) d++; return d; };

const byPar = new Map();
for (const e of pool) {
  if (!byPar.has(e.par)) byPar.set(e.par, []);
  byPar.get(e.par).push(e);
}
for (const b of byPar.values()) b.sort((a, c) => score(c) - score(a));

// how unlike every already-picked board this one is, in cells that differ; a
// board sharing a layout with any pick scores low however good it is on its own
const apart = (mk, masks) => masks.length ? Math.min(...masks.map(q => diff(mk, q))) : 36;

const picked = [], masks = [], used = new Set();
for (const want of RAMP) {
  let got = null, gotMask = null, gotRank = -1;
  const bucket = byPar.get(want) || [];
  // the bucket is already sorted by score; consider the strongest 120 and take
  // the most unlike-anything-so-far among them, quality breaking the tie
  for (const e of bucket.slice(0, 120)) {
    if (used.has(e.code)) continue;
    const mk = mask(dec(e.code));
    const r = apart(mk, masks) * 100 + score(e);
    if (r > gotRank) { gotRank = r; got = e; gotMask = mk; }
  }
  if (!got) { console.error('no candidate left for par ' + want); process.exit(1); }
  masks.push(gotMask);
  used.add(got.code);
  picked.push(got);
}
console.log('closest pair of picks differs in',
  Math.min(...masks.map((m, i) => Math.min(...masks.filter((_, j) => j !== i).map(q => diff(m, q))))),
  'of 36 cells');

// ---- verify every pick from its encoded string ----
let bad = 0;
for (let i = 0; i < picked.length; i++) {
  const ps = dec(picked[i].code);
  const why = legal(ps);
  const p = why ? -1 : par(ps);
  if (why || p !== picked[i].par) {
    console.error('level ' + (i + 1) + ': ' + (why || ('par ' + picked[i].par + ' but solver says ' + p)));
    bad++;
  }
}
if (bad) process.exit(1);

const lvs = picked.map(e => e.code).join(',');
const prs = picked.map(e => e.par).join(',');
fs.writeFileSync(__dirname + '/levels.json', JSON.stringify({ lvs, prs, picked }, null, 1));
console.log('lvs=split("' + lvs + '",",",false)');
console.log('prs=split("' + prs + '")');
console.log('all levels verified. pars', prs);
console.log('req/req2/mv/zones/back per level:');
console.log(picked.map((e, i) => (i + 1) + ':' + e.req + '/' + e.req2 + '/' + e.mv + '/' + e.zones + '/' + e.back).join(' '));
