// validate.js — proves the shipping cart is winnable at its printed par.
// Reads the level strings AND the pr table out of game.p8 itself (not the
// design doc), then for every level:
//   * the layout is well formed (196 cells, boxes == goals)
//   * a solution exists, and its optimum length is exactly pr[n]
//   * that optimum fits the move budget the cart enforces, lim()=pr+3, i.e.
//     the win lands before mv reaches the limit and boom() fires
// Run after any level, par or limit change: node validate.js
const fs = require('fs');
const path = require('path');
const here = p => path.join(__dirname, p);
const C = require('./solver');

const cart = fs.readFileSync(here('game.p8'), 'utf8');
const pr = /^pr=split"([\d,]+)"$/m.exec(cart)[1].split(',').map(Number);
const lvs = [...cart.matchAll(/^ "([^"]{196})",\s*--\s*(\d+)$/gm)].map(m => m[1]);
if (lvs.length !== 25) throw new Error(`found ${lvs.length} levels in the cart`);

const SLACK = 3;                    // lim() = pr[cur]+SLACK
let bad = 0;
lvs.forEach((s, n) => {
  const rows = [];
  for (let y = 0; y < C.W; y++) rows.push(s.slice(y * C.W, y * C.W + C.W));
  const { wall, goal, p, b } = C.parse(rows);
  const goals = []; for (let i = 0; i < C.N; i++) if (goal[i]) goals.push(i);
  const errs = [];
  if (goals.length !== b.length) errs.push(`${b.length} boxes but ${goals.length} goals`);
  if (!p.length) errs.push('no players');

  const best = C.solve(wall, p, b, goals, 4e6);
  const par = pr[n], lim = par + SLACK;
  if (best === null) errs.push('UNSOLVABLE');
  else if (best.length > par) errs.push(`par says ${par} but optimum is ${best.length} — UNWINNABLE at par`);
  else if (best.length < par) errs.push(`par says ${par} but optimum is only ${best.length} (${best})`);
  else if (best.length >= lim) errs.push(`optimum ${best.length} does not fit limit ${lim}`);

  console.log(`lv${String(n + 1).padStart(2)}  ${p.length}p ${b.length}b  par ${String(par).padStart(2)}` +
    `  limit ${String(lim).padStart(2)}  best ${best === null ? '--' : String(best.length).padStart(2)}  ` +
    (errs.length ? 'FAIL: ' + errs.join('; ') : 'ok  ' + best));
  bad += errs.length ? 1 : 0;
});
console.log(bad ? `${bad} LEVELS BAD` : `all ${lvs.length} levels winnable at par, inside the move limit`);
process.exit(bad ? 1 : 0);
