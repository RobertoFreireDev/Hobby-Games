// Verifies the level data that actually ships. For each level:
//   - replays the stored optimal solution through the forward move rule and
//     checks it ends in a win, having drowned nobody on the way;
//   - checks no tile has only fatal exits;
//   - re-runs a full forward BFS on the shallow levels to confirm the stored
//     move count really is optimal (the deep ones are too big for that, and are
//     guaranteed optimal by construction in bake.js instead).
//
//   node solve.js          replay + dead-tile check
//   node solve.js --bfs    also BFS every level (slow: tens of minutes)

const { levels, paths } = require("./levels.js");
const { parse, step, deadTiles, solve, NAME } = require("./lib.js");

const BFS_UNTIL = process.argv.includes("--bfs") ? 1e9 : 40;
let allOk = true;

levels.forEach((s, i) => {
  const { tile, boxes, player } = parse(s);
  const path = paths[i];
  let cur = { px: player[0], py: player[1], bs: boxes.map(([x, y]) => y * 10 + x).sort((a, b) => a - b) };
  let why = null;
  for (let n = 0; n < path.length && !why; n++) {
    const r = step(tile, cur.px, cur.py, cur.bs, NAME.indexOf(path[n]));
    if (r === "blocked") why = "move " + (n + 1) + " (" + path[n] + ") is blocked";
    else if (r === "dead") why = "move " + (n + 1) + " (" + path[n] + ") drowns";
    else cur = r;
  }
  if (!why && !cur.bs.every((b) => tile[b] === 3)) why = "solution does not end in a win";

  const dead = deadTiles(s);
  let opt = "";
  if (!why && path.length < BFS_UNTIL) {
    const r = solve(s, 8000000);
    if (!r.ok) why = "forward BFS: " + r.why;
    else if (r.moves !== path.length) why = "BFS optimum is " + r.moves + ", stored path is " + path.length;
    else opt = "  bfs-optimal";
  }

  if (why || dead.length) allOk = false;
  console.log("level " + String(i + 1).padStart(2) + "  " + (why ? "FAIL  " + why : "OK  " +
    boxes.length + "box  " + String(path.length).padStart(3) + " moves" + opt) +
    (dead.length ? "   [no-safe-exit tiles: " + dead.join(" ") + "]" : ""));
});

console.log(allOk ? "ALL LEVELS SOLVABLE" : "SOME LEVELS BROKEN");
process.exit(allOk ? 0 : 1);
