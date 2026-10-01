// gen.js — builds __gfx__, __sfx__ and __music__ for STONE LOGIC.
// Reads games/stone/game.p8, keeps its __lua__ section, rewrites the assets.
// usage: node games/stone/gen.js
const fs = require('fs');
const path = require('path');
const CART = path.join(__dirname, 'game.p8');

// ---------------------------------------------------------------- sheet
// '.' = transparent (colour 14, freed by palt in the cart), '0' = black icon.
const T = 14;
const g = Array.from({ length: 128 }, () => new Array(128).fill(T));

function art(sx, sy, rows) {
  rows.forEach((row, j) => [...row].forEach((ch, i) => {
    if (ch !== '.') g[sy + j][sx + i] = parseInt(ch, 16);
  }));
}
function place(n, rows) {
  if (rows.length !== 8 || rows.some(r => r.length !== 8)) throw new Error('sprite ' + n + ' not 8x8');
  art((n % 16) * 8, Math.floor(n / 16) * 8, rows);
}

// six faces, silhouette-first, all black on transparent
place(1, [                    // 1 dot
  '..0000..',
  '.0.0000.',
  '00000000',
  '00000000',
  '00000000',
  '00000000',
  '.000000.',
  '..0000..']);
place(2, [                    // 2 bamboo — two bars, notched twice
  '.00..00.',
  '.00..00.',
  '........',
  '.00..00.',
  '.00..00.',
  '........',
  '.00..00.',
  '.00..00.']);
place(3, [                    // 3 wave — three crests
  '.00..00.',
  '0..00..0',
  '........',
  '.00..00.',
  '0..00..0',
  '........',
  '.00..00.',
  '0..00..0']);
place(4, [                    // 4 star — eight-point burst
  '0..00..0',
  '.0.00.0.',
  '..0000..',
  '00000000',
  '00000000',
  '..0000..',
  '.0.00.0.',
  '0..00..0']);
place(5, [                    // 5 peak — notched mountain
  '...00...',
  '..0000..',
  '..0..0..',
  '..0..0..',
  '.00..00.',
  '.000000.',
  '00000000',
  '00000000']);
place(6, [                    // 6 cross
  '..0000..',
  '..0..0..',
  '000..000',
  '00....00',
  '00....00',
  '000..000',
  '..0..0..',
  '..0000..']);
place(8, [                    // 8 the "?" a buried stone shows
  '..0000..',
  '.00..00.',
  '.....00.',
  '...000..',
  '...00...',
  '........',
  '...00...',
  '...00...']);

// ---------------------------------------------------------------- sheet out

const gfx = g.map(row => row.map(c => c.toString(16)).join(''));
gfx.forEach((l, i) => { if (l.length !== 128) throw new Error('gfx line ' + i); });
// trim the all-transparent tail rows PICO-8 would drop anyway, keep 2 sprite rows
const gfxOut = gfx.slice(0, 16);

// ---------------------------------------------------------------- sound
// note = [pitch, waveform, volume, effect]; pitch 0..63 semitones from C-0
const R = null;                                   // rest
function sfx(speed, notes, loopS = 0, loopE = 0) {
  const n = notes.slice(0, 32);
  while (n.length < 32) n.push(R);
  const hx = (v, d = 2) => v.toString(16).padStart(d, '0');
  let s = '00' + hx(speed) + hx(loopS) + hx(loopE);
  for (const nt of n) s += nt ? hx(nt[0]) + hx(nt[1], 1) + hx(nt[2], 1) + hx(nt[3], 1) : '00000';
  if (s.length !== 168) throw new Error('sfx len ' + s.length);
  return s;
}
// scale helper: C minor pentatonic-ish, pitch numbers
const P = { c2: 24, d2: 26, ds2: 27, f2: 29, g2: 31, gs2: 32, as2: 34, c3: 36, ds3: 39, f3: 41, g3: 43, gs3: 44, as3: 46, c4: 48, ds4: 51, f4: 53, g4: 55, c5: 60 };

const S = [];
// 0 cursor blip — three pitches, one per layer; played as sfx(0,-1,layer-1,1)
S[0] = sfx(6, [[P.c4, 5, 3, 0], [P.g3, 5, 3, 0], [P.ds3, 5, 3, 0]]);
// 1 select — rising
S[1] = sfx(5, [[P.g3, 4, 4, 0], [P.c4, 4, 5, 0], [P.ds4, 4, 4, 5]]);
// 2 deselect — falling
S[2] = sfx(5, [[P.c4, 4, 4, 0], [P.g3, 4, 3, 5]]);
// 3 match — five stacked arpeggios, offset 4*combo picks the higher one
S[3] = sfx(4, [
  [P.c3, 0, 5, 0], [P.ds3, 0, 5, 0], [P.g3, 0, 5, 0], [P.c4, 0, 4, 5],
  [P.ds3, 0, 5, 0], [P.g3, 0, 5, 0], [P.as3, 0, 5, 0], [P.ds4, 0, 4, 5],
  [P.f3, 0, 5, 0], [P.gs3, 0, 5, 0], [P.c4, 0, 5, 0], [P.f4, 0, 4, 5],
  [P.g3, 0, 5, 0], [P.as3, 0, 5, 0], [P.ds4, 0, 5, 0], [P.g4, 0, 4, 5],
  [P.c4, 0, 5, 0], [P.ds4, 0, 5, 0], [P.g4, 0, 5, 0], [P.c5, 0, 4, 5],
]);
// 4 mismatch — low buzz
S[4] = sfx(7, [[P.c2, 6, 4, 0], [P.c2, 3, 3, 3], [P.c2, 6, 2, 5]]);
// 5 reveal — soft chime
S[5] = sfx(8, [[P.c5, 5, 3, 0], [P.g4, 5, 2, 5]]);
// 6 win fanfare
S[6] = sfx(9, [
  [P.c3, 4, 5, 0], [P.g3, 4, 5, 0], [P.c4, 4, 5, 0], [P.ds4, 4, 6, 0],
  [P.g4, 4, 6, 0], R, [P.g4, 4, 6, 0], [P.c5, 4, 6, 5]]);
// 7 fail — descending
S[7] = sfx(12, [[P.ds3, 3, 5, 0], [P.c3, 3, 4, 0], [P.gs2, 3, 4, 0], [P.f2, 3, 3, 5]]);
// 8 unused
S[8] = sfx(16, []);
// 9 deal sweep
S[9] = sfx(5, [
  [P.c2, 7, 3, 0], [P.g2, 7, 3, 0], [P.c3, 7, 4, 0], [P.ds3, 7, 4, 0],
  [P.g3, 7, 4, 0], [P.c4, 7, 3, 5]]);

// --- music beds. 10/11 = ambient, 12/13 = ambient bass, 14/15 = tension
const amb = (notes) => sfx(22, notes, 0, 0);
S[10] = amb([
  [P.c4, 0, 3, 0], R, R, R, [P.ds4, 0, 2, 0], R, R, R,
  [P.g3, 0, 3, 0], R, R, R, [P.c4, 0, 2, 0], R, R, R,
  [P.as3, 0, 3, 0], R, R, R, [P.g3, 0, 2, 0], R, R, R,
  [P.ds3, 0, 3, 0], R, R, R, [P.g3, 0, 2, 0], R, R, R]);
S[11] = amb([
  [P.ds4, 0, 3, 0], R, R, R, [P.g4, 0, 2, 0], R, R, R,
  [P.c4, 0, 3, 0], R, R, R, [P.g3, 0, 2, 0], R, R, R,
  [P.f3, 0, 3, 0], R, R, R, [P.c4, 0, 2, 0], R, R, R,
  [P.ds3, 0, 3, 0], R, R, R, [P.c3, 0, 2, 0], R, R, R]);
S[12] = amb([
  [P.c2, 5, 3, 0], R, R, R, R, R, R, R,
  [P.c2, 5, 2, 0], R, R, R, R, R, R, R,
  [P.gs2, 5, 3, 0], R, R, R, R, R, R, R,
  [P.g2, 5, 2, 0], R, R, R, R, R, R, R]);
S[13] = amb([
  [P.f2, 5, 3, 0], R, R, R, R, R, R, R,
  [P.f2, 5, 2, 0], R, R, R, R, R, R, R,
  [P.ds2, 5, 3, 0], R, R, R, R, R, R, R,
  [P.c2, 5, 2, 0], R, R, R, R, R, R, R]);
// tension: same bed, tighter pulse
S[14] = sfx(16, [
  [P.c2, 5, 4, 0], R, [P.c2, 5, 2, 0], R, [P.gs2, 5, 3, 0], R, [P.c2, 5, 2, 0], R,
  [P.c2, 5, 4, 0], R, [P.c2, 5, 2, 0], R, [P.g2, 5, 3, 0], R, [P.f2, 5, 2, 0], R,
  [P.c2, 5, 4, 0], R, [P.c2, 5, 2, 0], R, [P.gs2, 5, 3, 0], R, [P.c2, 5, 2, 0], R,
  [P.ds2, 5, 4, 0], R, [P.ds2, 5, 2, 0], R, [P.f2, 5, 3, 0], R, [P.g2, 5, 2, 0], R]);
S[15] = sfx(16, [
  [P.c4, 7, 2, 2], R, R, R, R, R, R, R,
  [P.ds4, 7, 2, 2], R, R, R, R, R, R, R,
  [P.g4, 7, 2, 2], R, R, R, R, R, R, R,
  [P.ds4, 7, 2, 2], R, R, R, R, R, R, R]);

for (let i = 0; i < 16; i++) if (!S[i]) S[i] = sfx(16, []);

// patterns: 00-01 ambient loop, 02-03 tension loop
const MUS = [
  '01 0a0c4344',   // 0 ambient, loop start
  '02 0b0d4344',   // 1 ambient, loop end
  '01 0e0f4344',   // 2 tension, loop start
  '02 0e0f4344',   // 3 tension, loop end
];

// ---------------------------------------------------------------- splice
let cart = fs.readFileSync(CART, 'utf8');
const i = cart.search(/^__gfx__$/m);
if (i < 0) throw new Error('no __gfx__ marker');
// the label is cover art from labelgen.p8, not generated here: carry it
// across untouched, and keep it in its one legal slot between gfx and sfx
const lab = cart.match(/^__label__\n(?:[0-9a-f]{128}\n)+/m);
const out = cart.slice(0, i)
  + '__gfx__\n' + gfxOut.join('\n') + '\n'
  + (lab ? lab[0] : '')
  + '__sfx__\n' + S.map(s => s).join('\n') + '\n'
  + '__music__\n' + MUS.join('\n') + '\n';
fs.writeFileSync(CART, out);
console.log('gfx lines', gfxOut.length, 'sfx', S.length, 'music', MUS.length);
