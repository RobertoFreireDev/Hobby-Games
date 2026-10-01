// lockstep core: move resolution + BFS, shared by the generator and verifier.
const W = 14, N = 196;
const DIRS = [-1, 1, -14, 14];          // L R U D
const DNAME = ['L', 'R', 'U', 'D'];
const DVEC = [[-1,0],[1,0],[0,-1],[0,1]];

// state: {p:[sorted player cells], b:[sorted box cells]}
function key(p, b) {
  let s = '';
  for (const v of p) s += String.fromCharCode(v);
  s += 'ÿ';
  for (const v of b) s += String.fromCharCode(v);
  return s;
}

// one press. returns null if nothing moved, else [newP, newB]
function step(wall, p, b, di) {
  const d = DIRS[di], [dx, dy] = DVEC[di];
  const occ = new Uint8Array(N), box = new Int8Array(N).fill(-1);
  for (const c of p) occ[c] = 1;
  for (let i = 0; i < b.length; i++) box[b[i]] = i;
  // furthest along d first
  const ord = p.slice().sort((a, c) => ((c % W) * dx + ((c / W) | 0) * dy) - ((a % W) * dx + ((a / W) | 0) * dy));
  const np = ord.slice(), nb = b.slice();
  let moved = false;
  for (let k = 0; k < ord.length; k++) {
    const cur = np[k], t = cur + d;
    if (t < 0 || t >= N || wall[t]) continue;
    const bi = box[t];
    if (bi >= 0) {
      const u = t + d;
      if (u < 0 || u >= N || wall[u] || box[u] >= 0 || occ[u]) continue;
      box[t] = -1; box[u] = bi; nb[bi] = u;
      occ[cur] = 0; occ[t] = 1; np[k] = t; moved = true;
    } else if (occ[t]) {
      continue;
    } else {
      occ[cur] = 0; occ[t] = 1; np[k] = t; moved = true;
    }
  }
  if (!moved) return null;
  return [np.sort((a, c) => a - c), nb.sort((a, c) => a - c), np.length];
}

// how many players actually changed cell
function movedCount(p, np) {
  // both sorted; compare as multisets
  let same = 0;
  const s = new Set(p);
  for (const v of np) if (s.has(v)) same++;
  return p.length - same;
}

// full BFS from start. returns Map boxKey -> min depth, plus stats.
// allMoveOnly: restrict to presses where every player changes cell.
function bfs(wall, p0, b0, cap, allMoveOnly, maxDepth) {
  const seen = new Set();
  const best = new Map();
  let frontier = [[p0.slice().sort((a,c)=>a-c), b0.slice().sort((a,c)=>a-c)]];
  seen.add(key(frontier[0][0], frontier[0][1]));
  best.set(frontier[0][1].join(','), 0);
  let depth = 0;
  while (frontier.length) {
    depth++;
    const next = [];
    for (const [p, b] of frontier) {
      for (let di = 0; di < 4; di++) {
        const r = step(wall, p, b, di);
        if (!r) continue;
        const [np, nb] = r;
        if (allMoveOnly && movedCount(p, np) !== p.length) continue;
        const k = key(np, nb);
        if (seen.has(k)) continue;
        seen.add(k);
        const bk = nb.join(',');
        if (!best.has(bk)) best.set(bk, depth);
        next.push([np, nb]);
      }
    }
    if (seen.size > cap) return { best, states: seen.size, overflow: true, depth };
    if (maxDepth && depth >= maxDepth) return { best, states: seen.size, overflow: false, depth };
    frontier = next;
  }
  return { best, states: seen.size, overflow: false, depth };
}

// BFS to a specific goal box multiset, returning the move string.
function solve(wall, p0, b0, goals, cap) {
  const gk = goals.slice().sort((a,c)=>a-c).join(',');
  const seen = new Map();
  const sp = p0.slice().sort((a,c)=>a-c), sb = b0.slice().sort((a,c)=>a-c);
  if (sb.join(',') === gk) return '';
  seen.set(key(sp, sb), null);
  let frontier = [[sp, sb, key(sp, sb)]];
  while (frontier.length) {
    const next = [];
    for (const [p, b, pk] of frontier) {
      for (let di = 0; di < 4; di++) {
        const r = step(wall, p, b, di);
        if (!r) continue;
        const [np, nb] = r;
        const k = key(np, nb);
        if (seen.has(k)) continue;
        seen.set(k, [pk, di]);
        if (nb.join(',') === gk) {
          let path = [], cur = k;
          while (seen.get(cur)) { const [pp, dd] = seen.get(cur); path.push(DNAME[dd]); cur = pp; }
          return path.reverse().join('');
        }
        next.push([np, nb, k]);
      }
    }
    if (seen.size > cap) return null;
    frontier = next;
  }
  return null;
}

function parse(rows) {
  const s = rows.join('');
  const wall = new Uint8Array(N), goal = new Uint8Array(N), p = [], b = [];
  for (let i = 0; i < N; i++) {
    const c = s[i];
    if (c === '#') wall[i] = 1;
    if ('.*+'.includes(c)) goal[i] = 1;
    if ('$*'.includes(c)) b.push(i);
    if ('@+'.includes(c)) p.push(i);
  }
  return { wall, goal, p, b };
}

function render(wall, goalSet, p, b) {
  const g = new Set(goalSet), ps = new Set(p), bs = new Set(b);
  let out = [];
  for (let y = 0; y < W; y++) {
    let row = '';
    for (let x = 0; x < W; x++) {
      const i = x + y * W;
      if (wall[i]) row += '#';
      else if (bs.has(i)) row += g.has(i) ? '*' : '$';
      else if (ps.has(i)) row += g.has(i) ? '+' : '@';
      else if (g.has(i)) row += '.';
      else row += ' ';
    }
    out.push(row);
  }
  return out;
}

// The design doc is the source of truth for level data (gen.js splices it into
// the cart), so read levels straight out of it rather than out of the cart.
function readDoc(mdPath) {
  const md = require('fs').readFileSync(mdPath, 'utf8').split(/\r?\n/);
  const F = '```';
  const out = [];
  for (let i = 0; i < md.length; i++) {
    if (!/^### Level \d+$/.test(md[i])) continue;
    let j = i;
    while (md[j] !== F) j++;
    const rows = [];
    for (j++; md[j] !== F; j++) rows.push(md[j].padEnd(W, ' '));
    let sol = null;
    for (let k = j; k < j + 8 && !sol; k++) {
      const m = /^Par solution: `([LRUD]*)`$/.exec(md[k] || '');
      if (m) sol = m[1];
    }
    out.push({ rows, sol });
  }
  return out;
}

module.exports = { W, N, DIRS, DNAME, step, bfs, solve, parse, render, key, readDoc };
