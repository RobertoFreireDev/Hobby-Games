// musicgen.js -- rebuilds ring sort's score: __sfx__ 16.. and __music__.
//
// the old score was organ (wave 5) at speed 26-30 with leads at pitch
// 60-63. slow organ = church = funeral, and pitch 60 is ~2khz. this
// replaces it with tilted-saw leads and triangle arps, faster tempi,
// and a hard ceiling of pitch 43 (~784hz) on anything that carries a
// tune. sfx 0-15 (the game's sound effects) are left untouched.
const fs = require('fs');
const path = require('path');
const CART = path.join(__dirname, 'game.p8');

// ---------------------------------------------------------------- notes
const NM = {c:0, cs:1, d:2, ds:3, e:4, f:5, fs:6, g:7, gs:8, a:9, as:10, b:11};
const P = (n, o) => NM[n] + 12 * o;      // P('c',2)==24, roughly middle c
const h2 = n => n.toString(16).padStart(2, '0');

// melody register, kept between c-2 and g-3
const c2=P('c',2), d2=P('d',2), e2=P('e',2), f2=P('f',2), fs2=P('fs',2),
      g2=P('g',2), a2=P('a',2), b2=P('b',2),
      c3=P('c',3), d3=P('d',3), e3=P('e',3), g3=P('g',3);

// waveforms: 0 triangle, 1 tilted saw, 3 square, 4 pulse.
// 5 (organ) is deliberately never used.
const W_LEAD = 1, W_BASS = 1, W_ARP = 0;

// ------------------------------------------------------------- builders
// [pitch, steps] pairs; null pitch is a rest. must total 32 steps.
function seq(items, w, v) {
  const o = [];
  for (const [p, l] of items)
    for (let i = 0; i < l; i++) o.push(p == null ? 0 : [p, w, v]);
  if (o.length !== 32) throw new Error('seq is ' + o.length + ' steps, need 32');
  return o;
}
// two bars of eight eighth-notes, one pitch list per bar
function arp2(a, b, w, v) {
  const o = [];
  for (const p of [...a, ...b]) { o.push([p, w, v]); o.push([p, w, v]); }
  if (o.length !== 32) throw new Error('arp2 needs 8+8 pitches');
  return o;
}
// four chords of eight sixteenth-notes, cycling each 4-note voicing twice
function arpfast(chords, w, v) {
  const o = [];
  for (const c of chords) for (let i = 0; i < 8; i++) o.push([c[i % 4], w, v]);
  return o;
}
function sfxline(speed, notes) {
  let s = '00' + h2(speed) + '0000';
  for (const n of notes)
    s += n ? h2(n[0]) + n[1].toString(16) + n[2].toString(16) + '0' : '00000';
  return s;
}

// identical voices are shared rather than duplicated, so the score fits
// well inside the 64 sfx slots alongside the 16 sound effects
const sfx = [];            // index 0 here == sfx 16 in the cart
const seen = new Map();
function slot(speed, notes) {
  const s = sfxline(speed, notes);
  if (!seen.has(s)) { seen.set(s, 16 + sfx.length); sfx.push(s); }
  return seen.get(s);
}

const music = [];
function pattern(flag, ch) {
  music.push(h2(flag) + ' ' + [0,1,2,3].map(i =>
    ch[i] == null ? '44' : h2(ch[i])).join(''));
}

// ================================================================ intro
// c major, 128bpm. chords: C|Am  F|G  C|Em  F|G
const IS = 15;
const introMel = [
  [[g2,2],[a2,2],[c3,4],[b2,2],[a2,2],[g2,4],
   [e2,2],[g2,2],[a2,4],[g2,2],[e2,2],[d2,4]],
  [[f2,2],[a2,2],[c3,4],[d3,2],[c3,2],[a2,4],
   [b2,2],[g2,2],[b2,4],[d3,2],[b2,2],[g2,4]],
  [[c3,4],[b2,2],[a2,2],[g2,4],[a2,4],
   [b2,4],[a2,2],[g2,2],[e2,4],[g2,4]],
  [[a2,2],[c3,2],[d3,4],[c3,2],[a2,2],[f2,4],
   [g2,2],[a2,2],[b2,4],[d3,4],[c3,4]],
];
// walking root/fifth, one bar each
const bassI = r => [[r,3],[null,1],[r,3],[null,1],
                    [r+7,3],[null,1],[r,3],[null,1]];
const R = {C:12, Am:9, F:5, G:7, Em:4};
const introBass = [[R.C,R.Am], [R.F,R.G], [R.C,R.Em], [R.F,R.G]];
// arps voice-led so every pattern stays inside pitch 17..33
const A = {
  C:  [19,24,28,31,28,24,19,24],
  Am: [21,24,28,33,28,24,21,24],
  F:  [17,21,24,29,24,21,17,21],
  G:  [19,23,26,31,26,23,19,23],
  Em: [19,23,28,31,28,23,19,23],
};
const introArp = [['C','Am'], ['F','G'], ['C','Em'], ['F','G']];

for (let i = 0; i < 4; i++) {
  const m = slot(IS, seq(introMel[i], W_LEAD, 5));
  const [r0, r1] = introBass[i];
  const b = slot(IS, seq([...bassI(r0), ...bassI(r1)], W_BASS, 4));
  const [a0, a1] = introArp[i];
  const a = slot(IS, arp2(A[a0], A[a1], W_ARP, 2));
  pattern(i === 0 ? 1 : i === 3 ? 2 : 0, [m, b, a]);
}

// =============================================================== game a
// levels 1-10. c major, 96bpm, sparse lead so it sits under play.
const GA = 20;
const gaMel = [
  [[null,2],[g2,4],[e2,2],[null,2],[c2,4],[null,2],
   [null,2],[d2,4],[g2,2],[null,2],[b2,4],[null,2]],
  [[null,2],[a2,4],[g2,2],[null,2],[e2,4],[null,2],
   [null,2],[f2,4],[a2,2],[null,2],[c3,4],[null,2]],
  [[c3,4],[b2,2],[g2,2],[null,4],[e2,4],
   [g2,4],[b2,2],[g2,2],[null,4],[d2,4]],
  [[null,4],[f2,4],[a2,4],[c3,4],
   [b2,4],[g2,4],[null,4],[d2,4]],
];
const bassG = r => [[r,6],[null,2],[r,6],[null,2]];
const gaChords = [['C','G'], ['Am','F'], ['C','G'], ['F','G']];
const gaRoot = {C:R.C, G:R.G, Am:R.Am, F:R.F};

for (let i = 0; i < 4; i++) {
  const [k0, k1] = gaChords[i];
  const m = slot(GA, seq(gaMel[i], W_LEAD, 4));
  const b = slot(GA, seq([...bassG(gaRoot[k0]), ...bassG(gaRoot[k1])], W_BASS, 4));
  const a = slot(GA, arp2(A[k0], A[k1], W_ARP, 2));
  pattern(i === 0 ? 1 : i === 3 ? 2 : 0, [m, b, a]);
}

// =============================================================== game b
// levels 11-20. g major, a little quicker and more syncopated so the
// back half feels like it has picked up, without getting brighter.
const GB = 18;
const gbMel = [
  [[null,2],[g2,4],[b2,2],[null,2],[d3,4],[null,2],
   [null,2],[b2,4],[g2,2],[null,2],[e2,4],[null,2]],
  [[c3,4],[b2,2],[a2,2],[g2,4],[null,4],
   [a2,4],[b2,2],[d3,2],[b2,4],[null,4]],
  [[null,4],[d3,2],[b2,2],[g2,4],[fs2,4],
   [null,4],[b2,2],[a2,2],[e2,4],[g2,4]],
  [[a2,2],[c3,2],[d3,4],[c3,2],[a2,2],[g2,4],
   [fs2,2],[a2,2],[b2,4],[d3,4],[b2,4]],
];
const bassB = r => [[r,4],[null,2],[r,2],[r+7,4],[null,2],[r,2]];
const B = {
  G:  [19,23,26,31,26,23,19,23],
  Em: [19,23,28,31,28,23,19,23],
  C:  [19,24,28,31,28,24,19,24],
  D:  [18,21,26,30,26,21,18,21],
};
const gbChords = [['G','Em'], ['C','D'], ['G','Em'], ['C','D']];
const gbRoot = {G:7, Em:4, C:12, D:14};

for (let i = 0; i < 4; i++) {
  const [k0, k1] = gbChords[i];
  const m = slot(GB, seq(gbMel[i], W_LEAD, 4));
  const b = slot(GB, seq([...bassB(gbRoot[k0]), ...bassB(gbRoot[k1])], W_BASS, 4));
  const a = slot(GB, arp2(B[k0], B[k1], W_ARP, 2));
  pattern(i === 0 ? 1 : i === 3 ? 2 : 0, [m, b, a]);
}

// ================================================================== win
// two patterns, then stop. rises to g-3 (784hz) and no further.
const WS = 12;
const CH = {C:[24,28,31,36], F:[17,21,24,29], G:[19,23,26,31]};
const w1m = slot(WS, seq([[c2,2],[e2,2],[g2,2],[c3,2],[g2,2],[c3,2],
                          [e3,4],[d3,2],[e3,2],[g3,12]], W_LEAD, 6));
const w1b = slot(WS, seq([[12,8],[17,8],[19,8],[19,8]], W_BASS, 5));
const w1a = slot(WS, arpfast([CH.C, CH.F, CH.G, CH.G], W_ARP, 3));
const w2m = slot(WS, seq([[e3,4],[d3,4],[c3,24]], W_LEAD, 6));
const w2b = slot(WS, seq([[12,16],[12,16]], W_BASS, 5));
const w2a = slot(WS, arpfast([CH.C, CH.C, CH.C, CH.C], W_ARP, 3));
pattern(0, [w1m, w1b, w1a]);
pattern(4, [w2m, w2b, w2a]);   // 4 == stop

// ================================================================ splice
const src = fs.readFileSync(CART, 'utf8');
const nl = src.includes('\r\n') ? '\r\n' : '\n';
const iS = src.indexOf('__sfx__');
const iM = src.indexOf('__music__');
if (iS < 0 || iM < 0) throw new Error('cart is missing __sfx__ / __music__');

const oldSfx = src.slice(iS, iM).split(/\r?\n/).slice(1).filter(l => l.length);
const keep = oldSfx.slice(0, 16);          // sound effects, untouched
if (keep.length !== 16) throw new Error('expected 16 effect sfx, got ' + keep.length);

const out = src.slice(0, iS)
  + '__sfx__' + nl + [...keep, ...sfx].join(nl) + nl
  + '__music__' + nl + music.join(nl) + nl;
fs.writeFileSync(CART, out);

console.log('sfx 16..' + (15 + sfx.length) + '  (' + sfx.length + ' voices, '
  + (16 + sfx.length) + '/64 slots used)');
console.log('music: 0-3 intro, 4-7 game a, 8-11 game b, 12-13 win');
