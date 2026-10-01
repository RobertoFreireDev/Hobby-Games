// probe2.js -- how hard can a board of a given size actually get?
// samples many random walks and reports the distribution of the beam estimate.
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
  ['L10 K4C6 chain2', 4, 6, [[0, 1], [1, 2]]],
  ['L13 K4C7 chain3', 4, 7, [[0, 1], [1, 2], [2, 3]]],
  ['L16 K5C6 hub+ch', 5, 6, [[0, 1], [0, 2], [0, 3], [3, 4]]],
  ['L18 K5C7 hub4  ', 5, 7, [[0, 1], [0, 2], [0, 3], [0, 4]]],
  ['L20 K5C7 hub+ch', 5, 7, [[0, 1], [0, 2], [0, 3], [3, 4]]],
];

const rnd = S.mulberry32(99);
for (const [name, K, C, pairs] of cases) {
  const blocked = S.mkBlocked(pairs);
  const vals = [];
  const t0 = Date.now();
  for (let i = 0; i < 60; i++) {
    const steps = 40 + ((rnd() * 500) | 0);
    const st = walk(K, C, blocked, steps, rnd);
    const b = S.beam(st, K, C, blocked, 120, 400, rnd);
    if (b !== null) vals.push(b);
  }
  vals.sort((a, b) => a - b);
  const med = vals[vals.length >> 1];
  console.log(`${name} rings=${K * C}  n=${vals.length} min=${vals[0]} med=${med} ` +
    `p90=${vals[(vals.length * 0.9) | 0]} max=${vals[vals.length - 1]}  (${Date.now() - t0}ms)`);
}
