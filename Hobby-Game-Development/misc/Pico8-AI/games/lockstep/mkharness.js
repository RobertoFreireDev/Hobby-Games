// mkharness.js — writes _lstest.p8: game.p8 plus a driver that drives the
// cart's own trymove()/win()/boom() through three scenarios per level:
//   1 the optimum route wins, at par, without tripping the move limit
//   2 burning the whole budget without solving loses, and not one move early
//   3 a win landing on the very last allowed move still counts as a win
// Routes come from the cart itself (solver BFS), so this never drifts from
// what ships. Run: node mkharness.js && pico8 -x _lstest.p8
const fs = require('fs');
const path = require('path');
const here = p => path.join(__dirname, p);
const C = require('./solver');

const cart = fs.readFileSync(here('game.p8'), 'utf8');
const pr = /^pr=split"([\d,]+)"$/m.exec(cart)[1].split(',').map(Number);
const lvs = [...cart.matchAll(/^ "([^"]{196})",\s*--\s*\d+$/gm)].map(m => m[1]);
if (lvs.length !== 25) throw new Error(`found ${lvs.length} levels in the cart`);
const SLACK = 3;

// a route of exactly `len` legal presses that never completes the puzzle.
// deterministic: directions are tried in an order that rotates with depth, and
// the search is capped so a pathological level fails loudly instead of hanging.
function waste(wall, p0, b0, gk, len) {
  let budget = 2e5;
  const dfs = (p, b, out) => {
    if (out.length === len) return out;
    if (budget-- < 0) return null;
    for (let k = 0; k < 4; k++) {
      const di = (k + out.length) % 4;
      const r = C.step(wall, p, b, di);
      if (!r) continue;
      const [np, nb] = r;
      if (nb.join(',') === gk) continue;
      out.push(C.DNAME[di]);
      if (dfs(np, nb, out)) return out;
      out.pop();
    }
    return null;
  };
  return dfs(p0.slice().sort((a, c) => a - c), b0.slice().sort((a, c) => a - c), []);
}

const sols = [], wastes = [];
lvs.forEach((s, n) => {
  const rows = [];
  for (let y = 0; y < C.W; y++) rows.push(s.slice(y * C.W, y * C.W + C.W));
  const { wall, goal, p, b } = C.parse(rows);
  const goals = []; for (let i = 0; i < C.N; i++) if (goal[i]) goals.push(i);
  const gk = goals.slice().sort((x, y) => x - y).join(',');
  const best = C.solve(wall, p, b, goals, 4e6);
  if (best === null || best.length !== pr[n]) throw new Error(`lv${n + 1}: optimum ${best && best.length} != par ${pr[n]}`);
  const w = waste(wall, p, b, gk, pr[n] + SLACK);
  if (!w) throw new Error(`lv${n + 1}: no ${pr[n] + SLACK}-move losing route`);
  sols.push(best.toLowerCase());
  wastes.push(w.join('').toLowerCase());
});

const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
const driver = `
-- test driver
sol=split"${sols.join(',')}"
wst=split"${wastes.join(',')}"
function dset(a,b) end
function dget(a) return 0 end
function dir(c)
 return c=="l" and 1 or c=="r" and 2 or c=="u" and 3 or 4
end
function play(s,a,b)
 for k=a,b do trymove(dir(sub(s,k,k))) end
end
tf=0
function _draw() end
function _update()
 tf+=1
 if tf>1 then return end
 local bad=0
 for n=1,25 do
  local s,w=sol[n],wst[n]

  -- 1. the par route wins, at par, well inside the limit
  loadlev(n)
  play(s,1,#s)
  if wn==0 or bm>0 or mv!=#s or mv>pr[n] then
   printh("lv"..n.." par route FAIL wn="..wn.." bm="..bm.." mv="..mv.."/"..lim()) bad+=1
  end

  -- 2. reaching the limit unsolved is a loss, and not one move sooner
  loadlev(n)
  local early=0
  for k=1,#w do
   trymove(dir(sub(w,k,k)))
   if k<#w and bm>0 then early=k end
  end
  if bm==0 or wn>0 or mv!=lim() or early>0 then
   printh("lv"..n.." limit FAIL wn="..wn.." bm="..bm.." mv="..mv.."/"..lim().." early="..early) bad+=1
  end

  -- 3. a win on the very last allowed move is still a win
  loadlev(n)
  play(s,1,#s-1)
  mv=lim()-1
  trymove(dir(sub(s,#s,#s)))
  if wn==0 or bm>0 or mv!=lim() then
   printh("lv"..n.." last-move win FAIL wn="..wn.." bm="..bm.." mv="..mv.."/"..lim()) bad+=1
  else
   printh("lv"..n.." ok  par "..#s.."  limit "..lim())
  end
 end
 printh(bad==0 and "ALL 25 OK" or (bad.." FAILURES"))
 extcmd("shutdown")
end
`;
fs.writeFileSync(here('_lstest.p8'), cart.slice(0, i) + driver + '\n' + cart.slice(i));
console.log('wrote _lstest.p8');
