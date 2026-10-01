// trim any free turns a plan makes after the win press, then re-check it
'use strict';
const fs = require('fs');
const P = require('./plan.js');
const file = process.argv[2] || 'mazes.json';
const mazes = JSON.parse(fs.readFileSync(file, 'utf8'));
let cut = 0;
for (const m of mazes) {
  const r = P.replay(m, m.plan);
  if (!r.ok) throw new Error('plan does not win');
  if (r.moved !== m.movOpt || r.rots !== m.actOpt) throw new Error('plan cost drifted');
  cut += m.plan.length - r.used;
  m.plan = m.plan.slice(0, r.used);
  const r2 = P.replay(m, m.plan);
  if (!r2.ok || r2.used !== m.plan.length) throw new Error('trimmed plan broke');
}
fs.writeFileSync(file, JSON.stringify(mazes));
console.log('trimmed', cut, 'trailing presses across', mazes.length, 'plans');
