// verify-levels.js — independent check of the level data now sitting in game.p8.
// Parses the __lua__ level strings back out, re-solves every level with A*, and
// asserts geometry + par. Also emits the optimal move list for each level so the
// in-cart harness can replay it through the game's own mv().
// run: node games/gridlock/verify-levels.js
const fs = require('fs');
const N = 6, ROW = 2;
const cart = fs.readFileSync(__dirname + '/game.p8', 'utf8');
const lvsStr = cart.match(/lvs=split\("([^"]+)"/)[1];
const prsStr = cart.match(/prs=split\("([^"]+)"/)[1];
const levels = lvsStr.split(',');
const pars = prsStr.split(',').map(Number);
const CH = '012345';

function parse(code) {
  const ps = [];
  for (let i = 0; i < code.length; i += 4)
    ps.push({ x: CH.indexOf(code[i]), y: CH.indexOf(code[i + 1]), l: +code[i + 2], d: +code[i + 3] });
  return ps;
}

const key = s => String.fromCharCode.apply(null, s);

function solve(ps) {
  const n = ps.length, goalX = N - ps[0].l;
  const L = ps.map(p => p.l), D = ps.map(p => p.d);
  const st0 = new Int8Array(n * 2);
  for (let i = 0; i < n; i++) { st0[i * 2] = ps[i].x; st0[i * 2 + 1] = ps[i].y; }
  const g = new Int8Array(N * N);
  const fill = st => {
    g.fill(-1);
    for (let i = 0; i < n; i++) {
      const x = st[i * 2], y = st[i * 2 + 1];
      for (let k = 0; k < L[i]; k++) g[(y + (D[i] ? k : 0)) * N + x + (D[i] ? 0 : k)] = i;
    }
  };
  const h = st => {
    fill(st);
    const seen = new Set();
    for (let x = st[0] + L[0]; x < N; x++) { const o = g[ROW * N + x]; if (o > 0) seen.add(o); }
    return (goalX - st[0]) + seen.size;
  };
  const heap = [];
  const push = v => { heap.push(v); let i = heap.length - 1; while (i) { const p = (i - 1) >> 1; if (heap[p][0] <= heap[i][0]) break;[heap[p], heap[i]] = [heap[i], heap[p]]; i = p; } };
  const pop = () => { const t = heap[0], l = heap.pop(); if (heap.length) { heap[0] = l; let i = 0; for (;;) { const a = 2 * i + 1, b = a + 1; let m = i; if (a < heap.length && heap[a][0] < heap[m][0]) m = a; if (b < heap.length && heap[b][0] < heap[m][0]) m = b; if (m === i) break;[heap[m], heap[i]] = [heap[i], heap[m]]; i = m; } } return t; };
  const best = new Map([[key(st0), 0]]);
  const from = new Map();
  push([h(st0), 0, st0]);
  while (heap.length) {
    const [, gc, st] = pop();
    const k = key(st);
    if (best.get(k) < gc) continue;
    if (st[0] === goalX) {
      const path = [];
      let cur = k;
      while (from.has(cur)) { const [pk, i, dx, dy] = from.get(cur); path.push([i, dx, dy]); cur = pk; }
      return { par: gc, path: path.reverse() };
    }
    fill(st);
    for (let i = 0; i < n; i++) {
      const x = st[i * 2], y = st[i * 2 + 1];
      for (const s of [-1, 1]) {
        let ex, ey;
        if (D[i] === 0) { ey = y; ex = s < 0 ? x - 1 : x + L[i]; }
        else { ex = x; ey = s < 0 ? y - 1 : y + L[i]; }
        if (ex < 0 || ex >= N || ey < 0 || ey >= N || g[ey * N + ex] !== -1) continue;
        const ns = Int8Array.from(st);
        if (D[i] === 0) ns[i * 2] = x + s; else ns[i * 2 + 1] = y + s;
        const nk = key(ns), ng = gc + 1;
        if (best.has(nk) && best.get(nk) <= ng) continue;
        best.set(nk, ng);
        from.set(nk, [k, i, D[i] === 0 ? s : 0, D[i] === 0 ? 0 : s]);
        push([ng + h(ns), ng, ns]);
        fill(st);
      }
    }
  }
  return null;
}

let bad = 0;
const sols = [];
const WANT = 12;
if (levels.length !== WANT) { console.log('FAIL level count ' + levels.length); bad++; }
if (pars.length !== WANT) { console.log('FAIL par count ' + pars.length); bad++; }

levels.forEach((code, n) => {
  const ps = parse(code);
  const tag = 'lv' + (n + 1);
  // geometry
  const occ = new Set();
  for (const p of ps) {
    if (p.l < 2 || p.l > 3 || (p.d !== 0 && p.d !== 1)) { console.log(tag + ' FAIL piece shape'); bad++; }
    for (let k = 0; k < p.l; k++) {
      const x = p.x + (p.d ? 0 : k), y = p.y + (p.d ? k : 0);
      if (x < 0 || x >= N || y < 0 || y >= N) { console.log(tag + ' FAIL out of bounds'); bad++; }
      const c = y * N + x;
      if (occ.has(c)) { console.log(tag + ' FAIL overlap at ' + x + ',' + y); bad++; }
      occ.add(c);
    }
  }
  const m = ps[0];
  if (m.d !== 0 || m.l !== 2 || m.y !== ROW) { console.log(tag + ' FAIL main piece'); bad++; }
  if (ps.length !== 12) { console.log(tag + ' FAIL ' + ps.length + ' pieces, want 12'); bad++; }
  if (pars[n] < 15 || pars[n] > 25) { console.log(tag + ' FAIL par ' + pars[n] + ' outside 15..25'); bad++; }
  // no other horizontal piece may sit on the exit row and sneak out of the gap
  for (let i = 1; i < ps.length; i++)
    if (ps[i].d === 0 && ps[i].y === ROW) { console.log(tag + ' FAIL slider on exit row'); bad++; }
  // par
  const r = solve(ps);
  if (!r) { console.log(tag + ' FAIL unsolvable'); bad++; return; }
  if (r.par !== pars[n]) { console.log(tag + ' FAIL par ' + pars[n] + ' but solver says ' + r.par); bad++; }
  sols.push(r.path);
});

// the game is a ramp: the move budget must never shrink as you go
for (let i = 1; i < pars.length; i++)
  if (pars[i] < pars[i - 1]) { console.log('lv' + (i + 1) + ' FAIL par drops below lv' + i); bad++; }

fs.writeFileSync(__dirname + '/solutions.json', JSON.stringify(sols));
console.log(bad ? bad + ' PROBLEMS' : 'all ' + WANT + ' levels ok: geometry, solvable, par exact, par climbs');
console.log('total optimal moves across the game: ' + sols.reduce((a, p) => a + p.length, 0));
