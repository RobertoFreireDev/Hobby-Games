// verify.js — proves every level in lockstep-design.md, from the doc alone:
//   * the printed par solution actually solves it
//   * no shorter solution exists (breadth-first over the whole state space)
//   * it cannot be solved by presses that move every player, i.e. the level
//     really does require anchoring somebody
// Run after any level edit: node verify.js
const C = require('./solver');
const lvls = C.readDoc('lockstep-design.md');
let bad = 0;
lvls.forEach((lv, n) => {
  const { wall, goal, p, b } = C.parse(lv.rows);
  const goals = []; for (let i = 0; i < C.N; i++) if (goal[i]) goals.push(i);
  const gk = goals.slice().sort((x, y) => x - y).join(',');
  const errs = [];
  lv.rows.forEach((r, y) => { if (r.length !== C.W) errs.push(`row ${y} is ${r.length} wide`); });
  if (goals.length !== b.length) errs.push(`${b.length} boxes but ${goals.length} goals`);

  // replay the printed route
  let cp = p.slice().sort((x, y) => x - y), cb = b.slice().sort((x, y) => x - y);
  for (const c of lv.sol || '') {
    const r = C.step(wall, cp, cb, C.DNAME.indexOf(c));
    if (!r) { errs.push(`route stalls at move "${c}"`); break; }
    [cp, cb] = r;
  }
  if (cb.join(',') !== gk) errs.push('printed route does not solve it');

  const best = C.solve(wall, p, b, goals, 4e6);
  if (best === null) errs.push('UNSOLVABLE');
  else if (best.length !== (lv.sol || '').length) errs.push(`par is ${lv.sol.length} but optimum is ${best.length} (${best})`);

  const sync = C.bfs(wall, p, b, 300000, true, (lv.sol || '').length);
  if (sync.best.has(gk)) errs.push('solvable without ever anchoring anyone');

  console.log(`lv${String(n + 1).padStart(2)}  ${p.length}p ${b.length}b  par ${String(lv.sol.length).padStart(2)}  ` +
    (errs.length ? 'FAIL: ' + errs.join('; ') : 'ok'));
  bad += errs.length ? 1 : 0;
});
console.log(bad ? `${bad} LEVELS BAD` : `all ${lvls.length} levels verified`);
process.exit(bad ? 1 : 0);
