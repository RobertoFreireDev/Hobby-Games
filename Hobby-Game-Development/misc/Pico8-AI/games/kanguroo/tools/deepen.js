// Backward BFS from every winning state (all boxes on goals) over the inverse of
// the cart's movement rules. A state's BFS depth is *exactly* its optimal
// solution length, so a level picked out of layer N is solvable by construction
// and takes N moves at best play.
//
//   node deepen.js <draft index 1..16> [targetDepth]
//
// Reverse transitions for a move in direction d landing in state (p, B):
//   un-push  : the box now at p+d goes back to p, the player back to p-d
//   un-hop1  : the player goes back to p-d; p+d must be wall or box (what
//              shortened the jump)
//   un-jump2 : the player goes back to p-2d, sailing over p-d
// In all three the pre-move player tile must be standable and box-free.

const { parse, deadTiles } = require("./lib.js");
const DX = [-1, 1, 0, 0], DY = [0, 0, -1, 1];

// Drafts hold terrain only; tolerate (and ignore) any box/player chars in them.
const terrain = (r) => r.replace(/B/g, "o").replace(/[bp]/g, ".");
const board = (rows) =>
  ["~~~~~~~~~~", ...rows.map((r) => "~" + terrain(r) + "~"), "~~~~~~~~~~"].join("");

function deepen(rows, opts = {}) {
  const maxStates = opts.maxStates || 6000000;
  const { tile } = parse(board(rows));
  const goals = [];
  for (let i = 0; i < 100; i++) if (tile[i] === 3) goals.push(i);
  if (!goals.length) throw new Error("terrain has no goals");

  const wall = (i) => i < 0 || i > 99 || tile[i] === 1;
  const stand = (i) => i >= 0 && i <= 99 && (tile[i] === 0 || tile[i] === 3);
  const idx = (x, y) => (x < 0 || x > 9 || y < 0 || y > 9) ? -1 : y * 10 + x;
  const enc = (p, bs) => String.fromCharCode(p, ...bs);

  const seen = new Set();
  const g = goals.slice().sort((a, b) => a - b);
  const layers = [[]];
  for (let i = 0; i < 100; i++) {
    if (!stand(i) || g.indexOf(i) >= 0) continue;
    seen.add(enc(i, g));
    layers[0].push({ p: i, bs: g });
  }

  let states = layers[0].length;
  while (states < maxStates) {
    const cur = layers[layers.length - 1];
    const next = [];
    const push = (p, bs) => {
      const k = enc(p, bs);
      if (seen.has(k)) return;
      seen.add(k);
      states++;
      next.push({ p, bs });
    };
    for (const st of cur) {
      const px = st.p % 10, py = Math.floor(st.p / 10);
      const has = (i) => st.bs.indexOf(i) >= 0;
      if (has(st.p)) continue;
      for (let d = 0; d < 4; d++) {
        const dx = DX[d], dy = DY[d];
        const back1 = idx(px - dx, py - dy);
        const back2 = idx(px - dx * 2, py - dy * 2);
        const fwd1 = idx(px + dx, py + dy);
        const okBack1 = stand(back1) && !has(back1);

        if (okBack1 && fwd1 >= 0 && has(fwd1)) {          // un-push
          const bs = st.bs.slice();
          bs[bs.indexOf(fwd1)] = st.p;
          bs.sort((a, b) => a - b);
          push(back1, bs);
        }
        if (okBack1 && (wall(fwd1) || (fwd1 >= 0 && has(fwd1)))) push(back1, st.bs);   // un-hop1
        if (stand(back2) && !has(back2) && back1 >= 0 && !wall(back1) && !has(back1))  // un-jump2
          push(back2, st.bs);
      }
    }
    if (!next.length) break;
    layers.push(next);
  }
  return { layers, states, tile, goals, nb: goals.length, depth: layers.length - 1 };
}

function render(rows, st) {
  const a = board(rows).split("");
  for (const b of st.bs) a[b] = a[b] === "o" ? "B" : "b";
  a[st.p] = "p";
  return a.join("");
}

// Pick the nicest start at (or just under) a target depth: no box already
// parked on a goal, no tile whose every exit is fatal, boxes far from their
// goals and spread out.
function pick(rows, r, want) {
  const top = r.layers.length - 1;
  const target = want && want <= top ? want : top;
  for (let d = target; d >= Math.max(1, Math.floor(target / 2)); d--) {
    let best = null;
    for (const st of r.layers[d]) {
      const s = render(rows, st);
      // the cart level format has no glyph for a box or the player sitting on
      // a goal at load time, and a pre-parked box reads as half-solved anyway.
      if (st.bs.some((b) => r.tile[b] === 3) || r.tile[st.p] === 3) continue;
      let away = 0, spread = 0;
      const gx = (i) => i % 10, gy = (i) => Math.floor(i / 10);
      for (const b of st.bs) {
        let m = 99;
        for (const go of r.goals) m = Math.min(m, Math.abs(gx(b) - gx(go)) + Math.abs(gy(b) - gy(go)));
        away += m;
      }
      for (let a = 0; a < st.bs.length; a++) for (let b = a + 1; b < st.bs.length; b++)
        spread += Math.abs(gx(st.bs[a]) - gx(st.bs[b])) + Math.abs(gy(st.bs[a]) - gy(st.bs[b]));
      const k = -deadTiles(s).length * 100 + away * 4 + spread;
      if (!best || k > best.k) best = { s, k, depth: d, st };
    }
    if (best) return best;
  }
  return null;
}

// Walks a chosen start back down through the BFS layers with the *forward*
// move rule, which is an independent check that the reverse rules above really
// do describe the cart's movement: it must reach a won state in exactly as many
// moves as its layer index. Returns the move string, or a reason it failed.
function extract(r, depth, startState) {
  const { step, NAME } = require("./lib.js");
  const enc = (p, bs) => String.fromCharCode(p, ...bs);
  const sets = r.layers.map((L) => new Set(L.map((st) => enc(st.p, st.bs))));
  let cur = { px: startState.p % 10, py: Math.floor(startState.p / 10), bs: startState.bs };
  let path = "";
  for (let d = depth; d > 0; d--) {
    let moved = false;
    for (let dir = 0; dir < 4 && !moved; dir++) {
      const n = step(r.tile, cur.px, cur.py, cur.bs, dir);
      if (n === "blocked" || n === "dead") continue;
      if (!sets[d - 1].has(enc(n.py * 10 + n.px, n.bs))) continue;
      cur = n; path += NAME[dir]; moved = true;
    }
    if (!moved) return { ok: false, why: "no forward move from depth " + d };
  }
  const won = cur.bs.every((b) => r.tile[b] === 3);
  return won ? { ok: true, path } : { ok: false, why: "path did not end in a win" };
}

module.exports = { deepen, render, pick, board, extract };

if (require.main === module) {
  const drafts = require("./drafts.js");
  const { solve } = require("./lib.js");
  const i = (parseInt(process.argv[2], 10) || 1) - 1;
  const d = drafts[i];
  const want = process.argv[3] !== undefined ? parseInt(process.argv[3], 10) : d.want;
  const t0 = Date.now();
  const r = deepen(d.rows);
  const best = pick(d.rows, r, want);
  console.log(d.name + ": " + r.nb + " boxes, max depth " + r.depth + ", " +
    r.states + " states, " + (Date.now() - t0) + "ms");
  if (!best) { console.log("no clean start found"); return; }
  const chk = solve(best.s, 12000000);
  console.log("depth " + best.depth + "; forward check " +
    (chk.ok ? chk.moves + " moves  " + chk.path : "FAIL " + chk.why) +
    (deadTiles(best.s).length ? "  [dead: " + deadTiles(best.s).join(" ") + "]" : ""));
  console.log("// " + (i + 1) + " \u2014 " + d.name);
  console.log("[");
  for (let y = 0; y < 10; y++) console.log('"' + best.s.slice(y * 10, y * 10 + 10) + '"' + (y < 9 ? "," : "],"));
}
