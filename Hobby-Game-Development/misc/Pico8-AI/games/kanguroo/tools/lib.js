// shared model + BFS solver for kanguroo. movement rules match the cart exactly:
//   t1 wall/border            -> blocked (no state change)
//   t1 box, t2 free           -> push box to t2, player to t1
//   t1 box, t2 blocked        -> blocked
//   t2 wall/border/box        -> hop 1, land on t1
//   otherwise                 -> jump 2, land on t2
// landing on water (player or pushed box) is a loss: those states are pruned.

const DX = [-1, 1, 0, 0];
const DY = [0, 0, -1, 1];
const NAME = "LRUD";

function parse(s) {
  const tile = [];   // 0 sand, 1 rock, 2 water, 3 goal
  const boxes = [];
  let player = null;
  for (let i = 0; i < 100; i++) {
    const c = s[i];
    const x = i % 10, y = Math.floor(i / 10);
    let t = 0;
    if (c === "#") t = 1;
    else if (c === "~") t = 2;
    else if (c === "o" || c === "B") t = 3;
    tile[i] = t;
    if (c === "b" || c === "B") boxes.push([x, y]);
    if (c === "p") player = [x, y];
  }
  return { tile, boxes, player };
}

// bfs. returns {ok, moves, path, states} or {ok:false, why}
function solve(s, maxStates = 6000000) {
  const { tile, boxes, player } = parse(s);
  if (!player) return { ok: false, why: "no player start" };
  if (boxes.length === 0) return { ok: false, why: "no boxes" };
  const goals = [];
  for (let i = 0; i < 100; i++) if (tile[i] === 3) goals.push(i);
  if (goals.length !== boxes.length) {
    return { ok: false, why: "boxes " + boxes.length + " != goals " + goals.length };
  }

  const at = (x, y) => (x < 0 || x > 9 || y < 0 || y > 9) ? 1 : tile[y * 10 + x];
  const key = (px, py, bs) => px + "," + py + "|" + bs.slice().sort((a, b) => a - b).join(",");

  const start = { px: player[0], py: player[1], bs: boxes.map(([x, y]) => y * 10 + x) };
  const won = (bs) => bs.every((b) => tile[b] === 3);
  if (won(start.bs)) return { ok: true, moves: 0, path: "", states: 1 };

  const seen = new Set([key(start.px, start.py, start.bs)]);
  let frontier = [{ ...start, path: "" }];
  let depth = 0, states = 1;

  while (frontier.length && states < maxStates) {
    const next = [];
    depth++;
    for (const st of frontier) {
      for (let d = 0; d < 4; d++) {
        const dx = DX[d], dy = DY[d];
        const x1 = st.px + dx, y1 = st.py + dy;
        const x2 = x1 + dx, y2 = y1 + dy;
        const i1 = y1 * 10 + x1, i2 = y2 * 10 + x2;
        const bi1 = st.bs.indexOf(i1);
        const inb2 = x2 >= 0 && x2 <= 9 && y2 >= 0 && y2 <= 9;
        const box2 = inb2 && st.bs.indexOf(i2) >= 0;

        let npx, npy, nbs = st.bs;
        if (at(x1, y1) === 1) continue;                       // blocked
        else if (bi1 >= 0) {
          if (at(x2, y2) === 1 || box2) continue;             // blocked
          if (at(x2, y2) === 2) continue;                     // box drowns
          nbs = st.bs.slice(); nbs[bi1] = i2;
          npx = x1; npy = y1;
        } else if (at(x2, y2) === 1 || box2) {
          npx = x1; npy = y1;                                 // hop 1
        } else {
          npx = x2; npy = y2;                                 // jump 2
        }
        if (at(npx, npy) === 2) continue;                     // player drowns

        const k = key(npx, npy, nbs);
        if (seen.has(k)) continue;
        seen.add(k);
        states++;
        const path = st.path + NAME[d];
        if (won(nbs)) return { ok: true, moves: depth, path, states };
        next.push({ px: npx, py: npy, bs: nbs, path });
      }
    }
    frontier = next;
  }
  return { ok: false, capped: states >= maxStates, states, why: (states >= maxStates ? "state cap reached at " : "no solution (") + states + (states >= maxStates ? " states" : " states explored)") };
}

// from every tile the player could stand on, is some direction survivable?
function deadTiles(s) {
  const { tile, boxes } = parse(s);
  const at = (x, y) => (x < 0 || x > 9 || y < 0 || y > 9) ? 1 : tile[y * 10 + x];
  const bs = new Set(boxes.map(([x, y]) => y * 10 + x));
  const bad = [];
  for (let y = 0; y < 10; y++) for (let x = 0; x < 10; x++) {
    if (at(x, y) === 1 || at(x, y) === 2 || bs.has(y * 10 + x)) continue;
    let safe = false;
    for (let d = 0; d < 4; d++) {
      const dx = DX[d], dy = DY[d];
      const x1 = x + dx, y1 = y + dy, x2 = x + dx * 2, y2 = y + dy * 2;
      if (at(x1, y1) === 1) { safe = true; continue; }        // blocked = survivable
      if (bs.has(y1 * 10 + x1)) {
        if (at(x2, y2) === 1 || bs.has(y2 * 10 + x2)) { safe = true; continue; }
        if (at(x2, y2) !== 2 && at(x1, y1) !== 2) safe = true;
        continue;
      }
      const land = (at(x2, y2) === 1 || bs.has(y2 * 10 + x2)) ? at(x1, y1) : at(x2, y2);
      if (land !== 2) safe = true;
    }
    if (!safe) bad.push(x + "," + y);
  }
  return bad;
}

// how many of the four moves from the start are instantly fatal / how forgiving
function stats(s) {
  const { boxes } = parse(s);
  return { boxes: boxes.length };
}

// One forward move, exactly as the cart resolves it. Returns the next state,
// "blocked" if nothing moves, or "dead" if the player or a box lands in water.
function step(tile, px, py, bs, d) {
  const at = (x, y) => (x < 0 || x > 9 || y < 0 || y > 9) ? 1 : tile[y * 10 + x];
  const dx = DX[d], dy = DY[d];
  const x1 = px + dx, y1 = py + dy, x2 = x1 + dx, y2 = y1 + dy;
  const i1 = y1 * 10 + x1, i2 = y2 * 10 + x2;
  const inb1 = x1 >= 0 && x1 <= 9 && y1 >= 0 && y1 <= 9;
  const inb2 = x2 >= 0 && x2 <= 9 && y2 >= 0 && y2 <= 9;
  const bi1 = inb1 ? bs.indexOf(i1) : -1;
  const box2 = inb2 && bs.indexOf(i2) >= 0;
  if (at(x1, y1) === 1) return "blocked";
  let npx, npy, nbs = bs;
  if (bi1 >= 0) {
    if (at(x2, y2) === 1 || box2) return "blocked";
    if (at(x2, y2) === 2) return "dead";
    nbs = bs.slice(); nbs[bi1] = i2; nbs.sort((a, b) => a - b);
    npx = x1; npy = y1;
  } else if (at(x2, y2) === 1 || box2) { npx = x1; npy = y1; }
  else { npx = x2; npy = y2; }
  if (at(npx, npy) === 2) return "dead";
  return { px: npx, py: npy, bs: nbs };
}

module.exports = { parse, solve, deadTiles, stats, step, DX, DY, NAME };
