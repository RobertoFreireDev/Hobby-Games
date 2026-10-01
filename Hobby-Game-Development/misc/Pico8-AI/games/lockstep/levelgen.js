// Randomised level generator for lockstep.
//   node levelgen.js '<json opts>'  -- prints one candidate level as JSON
// opts: {idx,P,B,secs,cap,maxDepth,seed,minPar,overlap}
// Places players/boxes at random inside an arena's walls, breadth-first expands
// the reachable state space, and takes a deep reachable box configuration as the
// goal set: solvable by construction, par optimal by definition.
const C = require('./solver');

const o = JSON.parse(process.argv[2]);
const { idx, P, B } = o;
const secs = o.secs ?? 25, cap = o.cap ?? 400000, maxDepth = o.maxDepth ?? 20;
const minPar = o.minPar ?? 8, overlap = o.overlap ?? 0;
let seed = (o.seed ?? 1) >>> 0;
const rnd = n => { seed = (seed * 1664525 + 1013904223) >>> 0; return (seed / 4294967296 * n) | 0; };

const arena = C.readDoc('lockstep-design.md')[idx].rows.map(r => [...r].map(c => c === '#' ? '#' : ' ').join(''));
const { wall } = C.parse(arena);
const floors = []; for (let i = 0; i < 196; i++) if (!wall[i]) floors.push(i);
const corner = i => (wall[i - 1] || wall[i + 1]) && (wall[i - 14] || wall[i + 14]);

function place() {
  const used = new Set(), p = [], b = [];
  let guard = 0;
  while (p.length < P && guard++ < 9999) { const c = floors[rnd(floors.length)]; if (!used.has(c)) { used.add(c); p.push(c); } }
  while (b.length < B && guard++ < 9999) { const c = floors[rnd(floors.length)]; if (!used.has(c) && !corner(c)) { used.add(c); b.push(c); } }
  return [p, b];
}

const score = (par, sol) => par * 4 + [...sol].filter((c, i) => i && c !== sol[i - 1]).length;

let best = null;
const t0 = Date.now();
let tries = 0, seen = 0;
while (Date.now() - t0 < secs * 1000) {
  tries++;
  const [p, b] = place();
  if (b.length < B) continue;
  const r = C.bfs(wall, p, b, cap, false, maxDepth);
  const startB = new Set(b);
  const cands = [];
  for (const [bk, d] of r.best) {
    if (d < minPar) continue;
    const cells = bk.split(',').map(Number);
    if (cells.filter(c => startB.has(c)).length > overlap) continue;
    cands.push({ d, cells });
  }
  cands.sort((x, y) => y.d - x.d);
  for (const pick of cands.slice(0, 12)) {
    seen++;
    if (best && pick.d * 4 + 20 <= best.score) break;   // can't beat it even with max turns
    const sol = C.solve(wall, p, b, pick.cells, cap);
    if (sol === null || sol.length !== pick.d) continue;
    if (new Set([...sol]).size < 3) continue;           // a route that never turns is a boring route
    const s = score(pick.d, sol);
    if (best && s <= best.score) continue;
    const rs = C.bfs(wall, p, b, 200000, true, pick.d); // must be impossible fully synchronised
    if (rs.best.has(pick.cells.join(','))) continue;
    best = { score: s, par: pick.d, p, b, goals: pick.cells, sol, states: r.states };
  }
}
if (!best) { console.log(JSON.stringify({ idx, fail: true, tries })); process.exit(0); }
const rows = C.render(wall, best.goals, best.p, best.b);
console.log(JSON.stringify({ idx, P, B, par: best.par, sol: best.sol, rows, tries, cands: seen, states: best.states }));
