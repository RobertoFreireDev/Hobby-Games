// levelgen.js — PORTAL FLOW level authoring tool (offline, §7.2 of DESIGN.md).
//
// Two halves:
//   solve()  — exhaustive DFS with the four prunes from the design doc. Counts
//              solutions, stopping at 2, so uniqueness is decidable.
//   gen()    — random full-coverage boards: build a random hamiltonian path over
//              the grid (backbite mixing) with the portal pair as an extra edge,
//              then cut it into k coloured segments. Coverage is 100% by
//              construction; solve() then filters for a *unique* solution and,
//              on portal levels, proves the portal is load-bearing.
//
//   node levelgen.js          -> writes levels.json + prints the validation table
//   node levelgen.js verify   -> re-validates levels.json without regenerating
'use strict';
const fs = require('fs');
const path = require('path');

// ------------------------------------------------------------------ rng
function rng32(a) {
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ------------------------------------------------------------------ grid
function neighbours(w, h) {
  const nb = [];
  for (let i = 0; i < w * h; i++) {
    const x = i % w, y = (i / w) | 0, a = [];
    if (y > 0) a.push(i - w);
    if (x < w - 1) a.push(i + 1);
    if (y < h - 1) a.push(i + w);
    if (x > 0) a.push(i - 1);
    nb.push(a);
  }
  return nb;
}
const manhattan = (w, a, b) =>
  Math.abs((a % w) - (b % w)) + Math.abs(((a / w) | 0) - ((b / w) | 0));

// ------------------------------------------------------------------ solver
// dots[i] = colour 1..k or 0.  pa/pb = portal cell indices or -1.
// Returns {n: solution count capped at `cap`, first: path list, nodes, aborted}
function solve(w, h, dots, pa, pb, cap = 2, budget = 4000000) {
  const n = w * h;
  const nb = neighbours(w, h);
  let k = 0;
  for (const d of dots) if (d > k) k = d;

  const ea = new Int32Array(k + 1).fill(-1);
  const eb = new Int32Array(k + 1).fill(-1);
  for (let i = 0; i < n; i++) {
    const c = dots[i];
    if (c > 0) { if (ea[c] < 0) ea[c] = i; else eb[c] = i; }
  }
  for (let c = 1; c <= k; c++) if (eb[c] < 0) return { n: 0, bad: 'colour ' + c + ' not paired' };

  const own = new Int32Array(n);
  for (let i = 0; i < n; i++) if (dots[i] > 0) own[i] = dots[i];
  const head = new Int32Array(k + 1);
  for (let c = 1; c <= k; c++) head[c] = ea[c];

  let free = 0;
  for (let i = 0; i < n; i++) if (own[i] === 0) free++;

  const hasP = pa >= 0;
  const isP = (i) => hasP && (i === pa || i === pb);
  const twin = (i) => (i === pa ? pb : pa);

  // scratch buffers, reused every prune call
  const comp = new Int32Array(n);
  const stack = new Int32Array(n);
  const hMask = new Int32Array(n);   // per component, bitmask of flows with head adjacent
  const tMask = new Int32Array(n);   // ... with target adjacent

  function usable(m, c) {
    const cc = own[m];
    if (cc === 0) return true;
    if (cc < c) return false;          // a finished pipe is a wall
    if (cc > c) return true;           // an untouched endpoint dot
    return m === head[c] || m === eb[c];
  }

  function prune(c) {
    // (1) every free tile needs two ways through it
    for (let i = 0; i < n; i++) {
      if (own[i] !== 0) continue;
      let d = isP(i) ? 1 : 0;          // the portal edge is mandatory, so it counts
      for (const m of nb[i]) if (usable(m, c)) { d++; if (d >= 2) break; }
      if (d < 2) return false;
    }
    // (2) label free components (the portal pair fuses two of them)
    comp.fill(-1);
    let nc = 0;
    for (let i = 0; i < n; i++) {
      if (own[i] !== 0 || comp[i] >= 0) continue;
      let sp = 0; stack[sp++] = i; comp[i] = nc;
      while (sp) {
        const x = stack[--sp];
        for (const m of nb[x]) if (own[m] === 0 && comp[m] < 0) { comp[m] = nc; stack[sp++] = m; }
        if (isP(x)) { const p = twin(x); if (own[p] === 0 && comp[p] < 0) { comp[p] = nc; stack[sp++] = p; } }
      }
      nc++;
    }
    // (3) each component must be enterable and exitable by one same unfinished flow,
    //     and (4) each unfinished flow must still have a route to its twin.
    for (let i = 0; i < nc; i++) { hMask[i] = 0; tMask[i] = 0; }
    let needing = 0;
    for (let j = c; j <= k; j++) {
      const hj = head[j], tj = eb[j];
      let adjacent = false;
      for (const m of nb[hj]) {
        if (m === tj) adjacent = true;
        else if (own[m] === 0) hMask[comp[m]] |= 1 << j;
      }
      for (const m of nb[tj]) if (own[m] === 0) tMask[comp[m]] |= 1 << j;
      if (!adjacent) needing |= 1 << j;
    }
    for (let i = 0; i < nc; i++) {
      const both = hMask[i] & tMask[i];
      if (both === 0) return false;    // stranded region
      needing &= ~both;
    }
    return needing === 0;
  }

  let sols = 0, nodes = 0, aborted = false;
  const trail = [];
  let first = null;

  function dfs(c) {
    if (aborted || sols >= cap) return;
    if (++nodes > budget) { aborted = true; return; }
    if (c > k) {
      if (free === 0) { sols++; if (!first) first = trail.slice(); }
      return;
    }
    const hj = head[c];
    for (const nx of nb[hj]) {
      if (nx === eb[c]) {                       // twin dot: this colour is done
        head[c] = nx; trail.push([c, nx]);
        if (prune(c + 1)) dfs(c + 1);
        trail.pop(); head[c] = hj;
      } else if (own[nx] !== 0) {
        continue;
      } else if (isP(nx)) {                     // portal: consume both tiles
        const p = twin(nx);
        if (own[p] !== 0) continue;
        own[nx] = c; own[p] = c; head[c] = p; free -= 2;
        trail.push([c, nx], [c, p]);
        if (prune(c)) dfs(c);
        trail.pop(); trail.pop();
        own[nx] = 0; own[p] = 0; head[c] = hj; free += 2;
      } else {
        own[nx] = c; head[c] = nx; free--;
        trail.push([c, nx]);
        if (prune(c)) dfs(c);
        trail.pop();
        own[nx] = 0; head[c] = hj; free++;
      }
      if (aborted || sols >= cap) return;
    }
  }

  if (prune(1)) dfs(1);
  return { n: sols, first, nodes, aborted };
}

// ------------------------------------------------------------- hamiltonian
function snake(w, h) {
  const p = [];
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) p.push(y * w + (y % 2 ? w - 1 - x : x));
  return p;
}

// Backbite mixing: pick an endpoint, add an edge to a random neighbour, drop the
// edge that would close the cycle. Works on any graph, so the portal edge takes
// part like a normal one.
function backbite(p, adj, rnd, steps) {
  const n = p.length, pos = new Int32Array(n);
  for (let i = 0; i < n; i++) pos[p[i]] = i;
  const rev = (a, b) => {
    while (a < b) {
      const t = p[a]; p[a] = p[b]; p[b] = t;
      pos[p[a]] = a; pos[p[b]] = b; a++; b--;
    }
    if (a === b) pos[p[a]] = a;
  };
  for (let s = 0; s < steps; s++) {
    if (rnd() < 0.5) {
      const c = adj[p[0]], u = c[(rnd() * c.length) | 0], j = pos[u];
      if (j > 1) rev(0, j - 1);
    } else {
      const c = adj[p[n - 1]], u = c[(rnd() * c.length) | 0], j = pos[u];
      if (j < n - 2) rev(j + 1, n - 1);
    }
  }
  return p;
}

// ------------------------------------------------------------------ gen
function toRows(w, h, dots, pa, pb) {
  const rows = [];
  for (let y = 0; y < h; y++) {
    let s = '';
    for (let x = 0; x < w; x++) {
      const i = y * w + x;
      s += i === pa || i === pb ? 'P' : dots[i] ? String(dots[i]) : '.';
    }
    rows.push(s);
  }
  return rows;
}

// Sample valid boards for `ms` milliseconds and hand every one to `keep`.
// A hamiltonian path is expensive and a cut-set is nearly free, so each path is
// re-cut CUTS times — that is what makes the (low) uniqueness yield workable.
const CUTS = 40;
function sample(spec, seed, ms, keep) {
  const { w, h, k, portal, mindist, edgeportal, pdist } = spec;
  const rnd = rng32(seed);
  const n = w * h;
  const nb = neighbours(w, h);
  const onEdge = (i) => i % w === 0 || i % w === w - 1 || i < w || i >= n - w;
  const deadline = Date.now() + ms;

  while (Date.now() < deadline) {
    let pa = -1, pb = -1;
    if (portal) {
      for (let t = 0; t < 200; t++) {
        const a = (rnd() * n) | 0, b = (rnd() * n) | 0;
        if (a === b || nb[a].includes(b)) continue;
        if (manhattan(w, a, b) < (pdist || 3)) continue;
        if (!edgeportal && (onEdge(a) || onEdge(b))) continue;
        pa = a; pb = b; break;
      }
      if (pa < 0) continue;
    }
    const adj = nb.map((a, i) => (i === pa ? a.concat(pb) : i === pb ? a.concat(pa) : a));
    const p = backbite(snake(w, h), adj, rnd, 40 * n);
    let ipa = -1;
    if (portal) {
      const ia = p.indexOf(pa), ib = p.indexOf(pb);
      if (Math.abs(ia - ib) !== 1) continue;        // the portal edge went unused
      ipa = Math.min(ia, ib);
    }

    for (let rep = 0; rep < CUTS; rep++) {
      const cuts = new Set();
      let guard = 0;
      while (cuts.size < k - 1 && guard++ < 400) cuts.add(1 + ((rnd() * (n - 1)) | 0));
      if (cuts.size < k - 1) continue;
      if (portal && cuts.has(ipa + 1)) continue;    // no cut between the twin tiles
      const bounds = [0, ...[...cuts].sort((a, b) => a - b), n];
      let bad = false, longest = 0;
      const dots = new Int32Array(n);
      for (let c = 1; c <= k; c++) {
        const s = bounds[c - 1], e = bounds[c] - 1;
        if (e - s < 1) { bad = true; break; }
        const a = p[s], b = p[e];
        if (a === pa || a === pb || b === pa || b === pb) { bad = true; break; }  // §3.2.7
        if (manhattan(w, a, b) < mindist) { bad = true; break; }
        dots[a] = c; dots[b] = c;
        longest = Math.max(longest, e - s + 1);
      }
      if (bad) continue;
      if (spec.minlong && longest < spec.minlong) continue;
      if (spec.maxlong && longest > spec.maxlong) continue;

      const r = solve(w, h, dots, pa, pb, 2, 3000000);
      if (r.aborted || r.n !== 1) continue;
      if (portal) {
        const r2 = solve(w, h, dots, -1, -1, 1, 3000000);    // §7.1 rule 5
        if (r2.aborted || r2.n !== 0) continue;
      }
      keep({ rows: toRows(w, h, dots, pa, pb), longest, nodes: r.nodes });
    }
  }
}

// Difficulty is not something a random generator gives you for free, so author
// each slot by sampling many valid boards and keeping the one that best matches
// the §7 intent: `nodes` (how much search the solver needed) is the difficulty
// proxy, `longest` bounds the headline pipe the level is supposed to be about.
function author(spec, lvNo, ms, salt, taken) {
  let best = null, seen = 0;
  const keep = (c) => {
    const key = c.rows.join('/');
    if (taken && taken.has(key)) return;         // never ship the same board twice
    seen++;
    if (!best || c.nodes > best.nodes) best = c;
  };
  sample(spec, lvNo * 7919 + 104729 + salt * 15485863, ms, keep);
  if (!best && (spec.minlong || spec.maxlong)) {       // relax the shape target
    const relaxed = Object.assign({}, spec, { minlong: 0, maxlong: 0 });
    sample(relaxed, lvNo * 7919 + 6857 + salt * 15485863, ms, keep);
  }
  return best && Object.assign(best, { seen });
}

// ------------------------------------------------------------------ specs
// size / colours / portal, straight off the §7 progression table.
const SPECS = [
  /* 1  teach connect+fill      */ { w: 4, h: 4, k: 3, portal: 0 },
  /* 2  teach the portal        */ { w: 4, h: 4, k: 2, portal: 1 },
  /* 3  first routing choice    */ { w: 5, h: 5, k: 3, portal: 0, minlong: 8 },
  /* 4  portal mandatory        */ { w: 5, h: 5, k: 3, portal: 1, minlong: 9 },
  /* 5  two colours compete     */ { w: 5, h: 5, k: 4, portal: 1, minlong: 7 },
  /* 6  breather, long snakes   */ { w: 6, h: 6, k: 4, portal: 0, minlong: 11 },
  /* 7  portals opposite corners*/ { w: 6, h: 6, k: 4, portal: 1, minlong: 14, pdist: 8 },
  /* 8  obvious grab is wrong   */ { w: 6, h: 6, k: 5, portal: 1, minlong: 10 },
  /* 9  six short pipes         */ { w: 6, h: 6, k: 6, portal: 1, maxlong: 9 },
  /* 10 scale shock             */ { w: 7, h: 7, k: 5, portal: 0, minlong: 15 },
  /* 11 two rooms, one crossing */ { w: 7, h: 7, k: 5, portal: 1, minlong: 15 },
  /* 12 portal as a trap        */ { w: 7, h: 7, k: 6, portal: 1, minlong: 12 },
  /* 13 access is the puzzle    */ { w: 7, h: 7, k: 6, portal: 1, minlong: 13 },
  /* 14 max colours, no slack   */ { w: 7, h: 7, k: 7, portal: 1, minlong: 10 },
  /* 15 entry side matters      */ { w: 7, h: 7, k: 7, portal: 1, minlong: 12 },
  /* 16 finale, 15-tile pipe    */ { w: 7, h: 7, k: 7, portal: 1, minlong: 15 },
];
// levels 1 and 2 are the ones written out verbatim in DESIGN.md §6.1
const FIXED = {
  1: ['1...', '23.1', '.3.2', '....'],
  2: ['1..P', '2...', '2...', 'P..1'],
};

function parse(rows) {
  const w = rows[0].length, h = rows.length;
  const dots = new Int32Array(w * h);
  let pa = -1, pb = -1;
  rows.forEach((r, y) => [...r].forEach((ch, x) => {
    const i = y * w + x;
    if (ch === 'P') { if (pa < 0) pa = i; else pb = i; }
    else if (ch >= '1' && ch <= '7') dots[i] = +ch;
  }));
  return { w, h, dots, pa, pb };
}

function report(rows, label) {
  const { w, h, dots, pa, pb } = parse(rows);
  const r = solve(w, h, dots, pa, pb, 3, 8000000);
  let req = '-';
  if (pa >= 0) {
    const r2 = solve(w, h, dots, -1, -1, 1, 8000000);
    req = r2.n === 0 ? 'yes' : 'NO';
  }
  let k = 0; for (const d of dots) if (d > k) k = d;
  let minD = 99;
  for (let c = 1; c <= k; c++) {
    const idx = []; for (let i = 0; i < w * h; i++) if (dots[i] === c) idx.push(i);
    minD = Math.min(minD, manhattan(w, idx[0], idx[1]));
  }
  let longest = 0;
  if (r.first) {
    const len = {};
    for (const [c] of r.first) len[c] = (len[c] || 1) + 1;
    for (const c in len) longest = Math.max(longest, len[c]);
  }
  return {
    label, size: w + 'x' + h, k, portal: pa >= 0 ? 'yes' : '-',
    sols: r.n, req, minD, longest, nodes: r.nodes,
  };
}

// ------------------------------------------------------------------ main
const OUT = path.join(__dirname, 'levels.json');
const mode = process.argv[2];

if (mode === 'verify') {
  const lv = JSON.parse(fs.readFileSync(OUT, 'utf8')).levels;
  table(lv.map((rows, i) => report(rows, String(i + 1))));
} else {
  const levels = [];
  const taken = new Set();
  for (let i = 0; i < 16; i++) {
    const lvNo = i + 1;
    if (FIXED[lvNo]) {
      levels.push(FIXED[lvNo]); taken.add(FIXED[lvNo].join('/'));
      console.error('lv' + lvNo + ' fixed'); continue;
    }
    const spec = Object.assign({}, SPECS[i], {
      mindist: lvNo >= 5 ? 3 : 2,      // §7.1 rule 4
      edgeportal: lvNo >= 7,           // §7.1 rule 3
    });
    let got = null;
    for (let salt = 0; salt < 6 && !got; salt++)
      got = author(spec, lvNo, spec.w >= 7 ? 25000 : 8000, salt, taken);
    if (!got) throw new Error('could not author level ' + lvNo);
    console.error('lv' + lvNo + ' ok  longest=' + got.longest +
      ' nodes=' + got.nodes + ' (best of ' + got.seen + ')\n' +
      got.rows.map(r => '        ' + r).join('\n'));
    taken.add(got.rows.join('/'));
    levels.push(got.rows);
  }
  fs.writeFileSync(OUT, JSON.stringify({ levels }, null, 1));
  table(levels.map((rows, i) => report(rows, String(i + 1))));
}

function table(rs) {
  console.log('lv  size  cols  portal  sols  p-req  mindist  longest    nodes');
  for (const r of rs)
    console.log(
      r.label.padStart(2) + '  ' + r.size + '   ' + String(r.k).padStart(3) +
      '    ' + r.portal.padStart(4) + '   ' + String(r.sols).padStart(3) +
      '  ' + r.req.padStart(5) + '  ' + String(r.minD).padStart(6) +
      '   ' + String(r.longest).padStart(6) + '  ' + String(r.nodes).padStart(7));
  // levels 1-2 are the verbatim tutorials from DESIGN.md §6.1 — a forgiving,
  // multi-solution board is the right thing while the rules are being taught.
  const bad = rs.filter(r => (r.sols !== 1 && +r.label > 2) || r.req === 'NO');
  console.log(bad.length ? 'FAIL: ' + bad.map(r => r.label).join(',') : 'all 16 levels valid');
}
