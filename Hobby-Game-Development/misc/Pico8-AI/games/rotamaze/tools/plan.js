// rebuild a button-press plan from a solved config, and replay it
// against a straight port of the cart's rules.
'use strict';
const L = require('./lib.js');

// press codes: 0..3 arrows (l,r,u,d), 5 = X
function planPresses(cfg, exitTile, movCap) {
  let target = -1, tcost = 1e9;
  for (let f = 0; f < 4; f++) {
    const d = cfg.dist[exitTile * 4 + f];
    if (d >= 0 && d < tcost) { tcost = d; target = exitTile * 4 + f; }
  }
  if (target < 0) return null;

  let out = [], c = cfg, guard = 0;
  while (guard++ < 200) {
    const r = L.walkPath(c.board, c.seeds, movCap, target);
    out = r.presses.concat(out);
    const o = c.origin.get(r.seed);
    if (!o) return out;                       // reached the root config
    out = new Array(o.k).fill(5).concat(out);
    target = r.seed;
    c = o.cfg;
  }
  return null;
}

// exact port of trymv / rot in game.p8
function replay(maze, presses) {
  const bd = Uint8Array.from(maze.board);
  let pc = L.col(maze.start), pr = L.row(maze.start), pf = maze.face;
  let mov = maze.movBudget, act = maze.actBudget;
  let moved = 0, rots = 0, won = false, used = 0;
  const ec = L.col(maze.exit), er = L.row(maze.exit);
  for (const b of presses) {
    if (won) break;
    used++;
    if (b === 5) {
      if (act < 1 || mov < 1) return { ok: false, why: 'rot with no budget' };
      const nc = pc + L.DX[pf], nr = pr + L.DY[pf];
      if (nc < 0 || nc >= L.W || nr < 0 || nr >= L.H) return { ok: false, why: 'rot off grid' };
      const i = L.idx(nc, nr);
      bd[i] = L.rot1(bd[i]);
      act--; rots++;
      continue;
    }
    const d = b;
    const nc = pc + L.DX[d], nr = pr + L.DY[d];
    let blocked = false;
    if (nc < 0 || nc >= L.W || nr < 0 || nr >= L.H) blocked = true;
    else {
      if (bd[L.idx(pc, pr)] & L.WB[d]) blocked = true;
      if (bd[L.idx(nc, nr)] & L.OB[d]) blocked = true;
    }
    if (blocked) { pf = d; continue; }
    if (mov < 1) return { ok: false, why: 'move with no budget' };
    pc = nc; pr = nr; pf = d; mov--; moved++;
    if (pc === ec && pr === er) won = true;
  }
  return { ok: won, moved, rots, used, movLeft: mov, actLeft: act, why: won ? '' : 'never reached exit' };
}

module.exports = { planPresses, replay };
