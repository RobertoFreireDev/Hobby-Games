// probe: how do the generator knobs map onto the solved difficulty?
'use strict';
const L = require('./lib.js');
const G = require('./gen.js');

const rng = L.rng32(parseInt(process.argv[3] || '99', 10));
const n = parseInt(process.argv[2] || '40', 10);
const rows = [];
for (let i = 0; i < n; i++) {
  const p = {
    braid: 0.02 + rng() * 0.20,
    extra: (rng() * 40) | 0,
    thick: 0.05 + rng() * 0.25,
  };
  const c = G.candidate(rng, p);
  if (!c) { rows.push({ ...p, A: 'degen' }); continue; }
  const t0 = Date.now();
  const q = G.evaluate(c, 120);
  rows.push({
    braid: p.braid.toFixed(2), extra: p.extra, thick: p.thick.toFixed(2),
    gates: c.gates, walls: [...c.board].reduce((s, w) => s + (w & 1) + ((w >> 1) & 1) + ((w >> 2) & 1) + ((w >> 3) & 1), 0),
    zero: [...c.board].filter(w => w === 0).length,
    A: q.reject ? q.reject.slice(0, 12) : q.A, M: q.M ?? '', near: q.near ?? '',
    ms: Date.now() - t0,
  });
}
console.table(rows);
const ok = rows.filter(r => typeof r.A === 'number');
const hist = {};
for (const r of ok) hist[r.A] = (hist[r.A] || 0) + 1;
console.log('A histogram:', hist);
console.log('avg ms:', (rows.reduce((s, r) => s + (r.ms || 0), 0) / rows.length).toFixed(0));
