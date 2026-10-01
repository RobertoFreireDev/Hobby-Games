// probe.js -- measure what the solvers can actually do, per level size.
// throwaway calibration for gen-levels.js acceptance thresholds.
'use strict';
const S = require('./solver');

function solvedState(K, C) {
  const st = [];
  for (let i = 0; i < 8; i++) st.push(i < C ? new Array(K).fill(i) : []);
  return st;
}

function walk(K, C, blocked, steps, rnd) {
  let st = solvedState(K, C);
  let lastSrc = -1, lastDst = -1;
  for (let i = 0; i < steps; i++) {
    const ms = S.moves(st, K, blocked).filter((m) => !(m[0] === lastDst && m[1] === lastSrc));
    if (ms.length === 0) break;
    const m = ms[(rnd() * ms.length) | 0];
    st = S.apply(st, m);
    lastSrc = m[0]; lastDst = m[1];
  }
  return st;
}

const cases = [
  [2, 4, []], [2, 5, []], [2, 6, []], [2, 6, [[0, 3]]],
  [3, 5, [[0, 3]]], [3, 6, [[0, 3]]], [3, 6, [[0, 3], [1, 4]]], [3, 7, [[0, 3]]],
  [4, 5, [[0, 3], [1, 4]]], [4, 6, [[0, 1], [1, 2]]], [4, 7, [[0, 1], [1, 2]]],
  [5, 5, [[0, 1], [1, 2], [2, 3]]], [5, 6, [[0, 1], [1, 2], [2, 3]]],
  [5, 7, [[0, 1], [0, 2], [0, 3]]], [5, 7, [[0, 1], [0, 2], [0, 3], [3, 4]]],
];

const rnd = S.mulberry32(1234);
for (const [K, C, pairs] of cases) {
  const blocked = S.mkBlocked(pairs);
  const st = walk(K, C, blocked, 300, rnd);
  const t0 = Date.now();
  const a = S.astar(st, K, C, blocked, 400000);
  const t1 = Date.now();
  const b = S.bestSolution(st, K, C, blocked, rnd, 3, 300);
  const t2 = Date.now();
  console.log(
    `K=${K} C=${C} R=${pairs.length} rings=${K * C}  h0=${S.heur(st, K, C)}  ` +
    `astar=${JSON.stringify(a)} (${t1 - t0}ms)  beam=${b} (${t2 - t1}ms)`
  );
}
