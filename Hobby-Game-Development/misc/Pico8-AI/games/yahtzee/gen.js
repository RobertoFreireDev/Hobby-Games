// gen.js — builds __gfx__, __sfx__ and __music__ for HIGH ROLLER.
// Reads games/yahtzee/game.p8, keeps its __lua__ section, rewrites the assets.
// usage: node games/yahtzee/gen.js
const fs = require('fs');
const path = require('path');
const CART = path.join(__dirname, 'game.p8');

// ---------------------------------------------------------------- canvas
const T = 13;                       // colour 13 = sprite transparency
const g = [];
for (let y = 0; y < 128; y++) g.push(new Array(128).fill(T));

const px = (x, y, c) => {
  x = Math.round(x); y = Math.round(y);
  if (x >= 0 && x < 128 && y >= 0 && y < 128 && c !== null) g[y][x] = c;
};
const box = (x, y, w, h, c) => {
  for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) px(x + i, y + j, c);
};
// ascii art block: '.' = transparent, other chars = hex colour
const art = (x, y, rows) => {
  rows.forEach((row, j) => [...row].forEach((ch, i) => {
    if (ch !== '.') px(x + i, y + j, parseInt(ch, 16));
  }));
};

// ---------------------------------------------------------------- dice
const inRR = (x, y, w, h, r) => {
  const cx = Math.min(Math.max(x, r), w - 1 - r);
  const cy = Math.min(Math.max(y, r), h - 1 - r);
  const dx = x - cx, dy = y - cy;
  return dx * dx + dy * dy <= r * r + 1;
};

// pip layouts, 3x3 blocks
const PIPS = {
  1: [[6, 6]],
  2: [[3, 3], [10, 10]],
  3: [[3, 3], [6, 6], [10, 10]],
  4: [[3, 3], [10, 3], [3, 10], [10, 10]],
  5: [[3, 3], [10, 3], [6, 6], [3, 10], [10, 10]],
  6: [[3, 2], [10, 2], [3, 6], [10, 6], [3, 10], [10, 10]],
};

function die(ox, oy, face, blur) {
  const R = 4;
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
    if (!inRR(x, y, 16, 16, R)) continue;
    let c = 7;
    if (!inRR(x - 2, y - 2, 16, 16, R)) c = 6;          // bottom-right shade
    if (!inRR(x + 1, y + 1, 16, 16, R)) c = 15;         // top-left rim light
    // outline: inside pixel touching the outside
    if (!inRR(x - 1, y, 16, 16, R) || !inRR(x + 1, y, 16, 16, R) ||
      !inRR(x, y - 1, 16, 16, R) || !inRR(x, y + 1, 16, 16, R)) c = 0;
    if (blur && c === 7 && y % 3 === blur % 3) c = 6;   // motion streaks
    px(ox + x, oy + y, c);
  }
  if (blur) {
    // ghost pips, low contrast
    for (const [x, y] of PIPS[blur === 1 ? 5 : 2]) box(ox + x, oy + y, 3, 3, 6);
    for (let x = 2; x < 14; x += 3) px(ox + x, oy + 8, 5);
    return;
  }
  for (const [x, y] of PIPS[face]) {
    box(ox + x, oy + y, 3, 3, face === 1 ? 8 : 0);
    if (face === 1) {                                    // red ace pip
      px(ox + x + 1, oy + y, 14);
      box(ox + x - 1, oy + y - 1, 5, 1, 0);
      box(ox + x - 1, oy + y + 3, 5, 1, 0);
      box(ox + x - 1, oy + y, 1, 3, 0);
      box(ox + x + 3, oy + y, 1, 3, 0);
    }
  }
}

for (let f = 1; f <= 6; f++) die((f - 1) * 16, 0, f, 0);
die(96, 0, 1, 1);
die(112, 0, 2, 2);

// ---------------------------------------------------------------- ui row (y=16)
art(0, 16, [                     // 32/33: brass hold clamp, 16x8
  '................',
  '..0..........0..',
  '.090........090.',
  '.095........590.',
  '0099999999999900',
  '0555555555555550',
  '0444444444444440',
  '.00000000000000.',
]);
art(16, 16, [                    // 34: gold cursor chevron
  '...00...',
  '..0aa0..',
  '.0a99a0.',
  '0a9009a0',
  '0a90.09a',
  '.00...00',
  '........',
  '........',
]);
const SPARK = [
  ['........', '........', '...0....', '..070...', '...0....', '........', '........', '........'],
  ['........', '...0....', '..070...', '.07a70..', '..070...', '...0....', '........', '........'],
  ['...0....', '..0a0...', '.0aaa0..', '0aa7aa0.', '.0aaa0..', '..0a0...', '...0....', '........'],
  ['..0.0...', '.0a0a0..', '..0a0...', '0a0a0a0.', '..0a0...', '.0a0a0..', '..0.0...', '........'],
];
SPARK.forEach((a, i) => art(24 + i * 8, 16, a));
art(56, 16, ['........', '..0000..', '.077770.', '.077770.', '..0000..', '........', '........', '........']);
art(64, 16, ['........', '...00...', '..0770..', '..0770..', '...00...', '........', '........', '........']);
art(72, 16, ['........', '..000...', '.07770..', '..000...', '........', '........', '........', '........']);
art(80, 16, ['........', '..000...', '.06660..', '060660..', '.06660..', '..000...', '........', '........']);
art(88, 16, ['..000...', '.0a9a0..', '0a9990..', '0a9990..', '0a9990..', '.09990..', '..000...', '........']);
art(96, 16, [                    // spade
  '...00...', '..0000..', '.000000.', '00000000', '00000000', '..0000..', '...00...', '........']);
art(104, 16, ['.00..00.', '0880880.', '08888880', '08888880', '.088880.', '..0880..', '...00...', '........']);
art(112, 16, ['...00...', '..0880..', '.088880.', '08888880', '.088880.', '..0880..', '...00...', '........']);
art(120, 16, ['...00...', '..0000..', '.00.00..', '0000000.', '.00000..', '..000...', '..000...', '........']);

// ---------------------------------------------------------------- deco row (y=24)
art(0, 24, [                     // 48/49: art-deco fan corner, 16x8
  '4444444444444444',
  '4999944444444444',
  '4944994444444444',
  '4949449444444444',
  '4494444944444444',
  '4444444494444444',
  '4444444449444444',
  '4444444444944444',
]);
const RING = [
  ['........', '..0000..', '.077770.', '.07..70.', '.07..70.', '.077770.', '..0000..', '........'],
  ['.000000.', '07....70', '0......0', '0......0', '0......0', '0......0', '07....70', '.000000.'],
  ['.0.00.0.', '0......0', '........', '........', '........', '........', '0......0', '.0.00.0.'],
];
RING.forEach((a, i) => art(16 + i * 8, 24, a));
art(40, 24, ['...0....', '..0a0...', '0.0a0.0.', '.0aaa0..', '..0a0...', '.0a0a0..', '.0...0..', '........']);
art(48, 24, [                    // crown
  '........', '0.0.0.0.', '0a0a0a0.', '0aaaaa0.', '0a9a9a0.', '0999990.', '0000000.', '........']);
art(56, 24, [                    // ribbon
  '..000...', '.09990..', '0a9a90..', '.09990..', '.00000..', '.08.80..', '.08.80..', '..0..0..']);
art(64, 24, ['..0000..', '.077770.', '07888870', '07888870', '07888870', '07888870', '.077770.', '..0000..']);
art(72, 24, ['........', '..000...', '.07770..', '.07770..', '0077700.', '.07770..', '..070...', '...0....']);

// mini dealer faces 8x8 — neutral / smug / worried / stunned (sprites 58-61)
const MINI = [
  ['..000...', '.04440..', '.00000..', '0ffff0..', '0f0f00..', '0ffff0..', '0f000f0.', '.00000..'],
  ['..000...', '.04440..', '.00000..', '0ffff0..', '0f0f00..', '0ffff0..', '0f00ff0.', '.00000..'],
  ['..000...', '.04440..', '.00000..', '0ffff0..', '0f00f0..', '0f0f00..', '0f000f0.', '.00000..'],
  ['..000...', '.04440..', '.00000..', '0ffff0..', '0f0f0f0.', '0fffff0.', '0f0000f.', '.00000..'],
];
MINI.forEach((a, i) => art(80 + i * 8, 24, a));

// ---------------------------------------------------------------- dealer portraits 16x16 (y=32)
const HAT = '0000000000';
function dealer(ox, expr) {
  art(ox, 32, [
    '................',
    '.....000000.....',
    '....04444440....',
    '....04444440....',
    '..044444444440..',
    '..088888888800..',
    '..000000000000..',
    '....0ffffff0....',
    '...0ffffffff0...',
    '...0ffffffff0...',
    '...0ffffffff0...',
    '...0ffffffff0...',
    '....0ffffff0....',
    '.....000000.....',
    '......0880......',
    '.....000000.....',
  ]);
  // eyes + mouth per expression
  const eye = (x, y, kind) => {
    if (kind === 'open') { box(ox + x, oy0 + y, 2, 2, 0); }
    else if (kind === 'squint') { box(ox + x, oy0 + y, 2, 1, 0); }
    else if (kind === 'wide') { box(ox + x - 1, oy0 + y - 1, 4, 4, 7); box(ox + x, oy0 + y, 2, 2, 0); }
  };
  const oy0 = 32;
  if (expr === 0) { eye(5, 9, 'open'); eye(9, 9, 'open'); box(ox + 6, oy0 + 12, 4, 1, 0); }
  if (expr === 1) {                                  // smug: squint + smirk
    eye(5, 9, 'squint'); eye(9, 9, 'squint');
    box(ox + 4, oy0 + 8, 3, 1, 0); box(ox + 9, oy0 + 8, 3, 1, 0);
    art(ox + 5, oy0 + 11, ['..000', '.0...', '0....']);
  }
  if (expr === 2) {                                  // worried: raised brows + frown
    eye(5, 10, 'open'); eye(9, 10, 'open');
    art(ox + 3, oy0 + 7, ['.00.....00.']);
    art(ox + 5, oy0 + 13, ['.000.', '0...0']);
    px(ox + 12, oy0 + 9, 12); px(ox + 12, oy0 + 10, 12);
  }
  if (expr === 3) {                                  // stunned: wide eyes + open mouth
    eye(5, 8, 'wide'); eye(10, 8, 'wide');
    box(ox + 6, oy0 + 12, 4, 3, 0); box(ox + 7, oy0 + 13, 2, 1, 8);
  }
}
[0, 1, 2, 3].forEach(e => dealer(e * 16, e));

// ---------------------------------------------------------------- block font
const FONT = {
  'A': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
  'G': ['.###.', '#...#', '#....', '#..##', '#...#', '#...#', '.###.'],
  'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'I': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '#####'],
  'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
  'N': ['#...#', '##..#', '##..#', '#.#.#', '#..##', '#..##', '#...#'],
  'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'R': ['####.', '#...#', '#...#', '####.', '#..#.', '#...#', '#...#'],
  'S': ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
  'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  'W': ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '##.##', '#...#'],
  'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
  'Z': ['#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'],
  '!': ['..#..', '..#..', '..#..', '..#..', '..#..', '.....', '..#..'],
  ' ': ['.....', '.....', '.....', '.....', '.....', '.....', '.....'],
};

// 2x-scaled word with a 1px outline and a top-lit gold ramp
function word(ox, oy, s, ramp) {
  const mask = [];
  for (let y = 0; y < 16; y++) mask.push(new Array(s.length * 11 + 2).fill(0));
  [...s].forEach((ch, n) => {
    const gl = FONT[ch];
    for (let y = 0; y < 7; y++) for (let x = 0; x < 5; x++) {
      if (gl[y][x] !== '#') continue;
      for (let j = 0; j < 2; j++) for (let i = 0; i < 2; i++) mask[2 + y * 2 + j][1 + n * 11 + x * 2 + i] = 1;
    }
  });
  for (let y = 0; y < mask.length; y++) for (let x = 0; x < mask[0].length; x++) {
    if (mask[y][x]) { px(ox + x, oy + y, ramp[Math.min(ramp.length - 1, Math.max(0, y - 2))]); continue; }
    // outline where a neighbour is filled
    let near = false;
    for (let j = -1; j <= 1; j++) for (let i = -1; i <= 1; i++) {
      const r = mask[y + j]; if (r && r[x + i]) near = true;
    }
    if (near) px(ox + x, oy + y, 0);
  }
}
const GOLD = [7, 10, 10, 10, 9, 9, 9, 9, 9, 4, 4, 4, 4, 4];
const HOT = [7, 15, 15, 14, 14, 8, 8, 8, 8, 2, 2, 2, 2, 2];

word(0, 48, 'HIGH ROLLER', GOLD);   // 121x16 at (0,48)
word(0, 64, 'YAHTZEE!', HOT);       // 88x16  at (0,64)
word(0, 80, 'WIN', GOLD);           // 33x16
word(40, 80, 'LOSE', HOT);          // 44x16
word(88, 80, 'TIE', GOLD);          // 33x16

// felt seam tiles / spare deco, y=96: a subtle woven texture strip
for (let y = 96; y < 104; y++) for (let x = 0; x < 128; x++) {
  g[y][x] = ((x + y) % 4 === 0) ? 11 : ((x * 3 + y) % 7 === 0 ? 1 : 3);
}

// ---------------------------------------------------------------- gfx text
const hex = n => n.toString(16);
const gfx = g.map(r => r.map(hex).join(''));
gfx.forEach((l, i) => { if (l.length !== 128) throw new Error('gfx line ' + i + ' = ' + l.length); });

// ---------------------------------------------------------------- audio
const SEMI = { c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11 };
function nn(s) {                     // "a#3" / "eb2" / "c4" -> pitch, C0 = 0
  const m = s.match(/^([a-g])([#b]?)(-?\d)$/);
  if (!m) throw new Error('bad note ' + s);
  let p = SEMI[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0) + parseInt(m[3]) * 12;
  if (p < 0 || p > 63) throw new Error('note out of range: ' + s + ' = ' + p);
  return p;
}
const h1 = n => n.toString(16);
const h2 = n => n.toString(16).padStart(2, '0');
// note: [name|pitch, wave, vol, effect] or null for a rest
function note(n) {
  if (!n) return '00000';
  const p = typeof n[0] === 'string' ? nn(n[0]) : n[0];
  return h2(p) + h1(n[1]) + h1(n[2]) + h1(n[3] || 0);
}
const SFX = [];
function sf(idx, speed, notes, ls = 0, le = 0) {
  const ns = notes.slice(0, 32);
  while (ns.length < 32) ns.push(null);
  SFX[idx] = '01' + h2(speed) + h2(ls) + h2(le) + ns.map(note).join('');
}
const rest = n => new Array(n).fill(null);

// --- fx -------------------------------------------------------------
sf(0, 3, [...Array(12)].map((_, i) => [0x18 + (i * 5) % 14, 6, i % 3 === 0 ? 3 : 2, 0]), 0, 10);
sf(1, 4, [['g2', 6, 5, 3], ['c2', 6, 3, 3], ['c1', 6, 2, 3]]);
sf(2, 3, [['c3', 6, 4, 0], ['g2', 6, 2, 0]]);
sf(3, 3, [['g2', 6, 3, 0], ['c3', 6, 2, 5]]);
sf(4, 2, [['c4', 3, 3, 0]]);
sf(5, 4, [['c4', 5, 5, 0], ['g4', 5, 5, 0]]);
sf(6, 8, [['e2', 2, 5, 3], ['c2', 2, 4, 3]]);
sf(7, 2, [['e4', 4, 3, 0]]);
sf(8, 6, [['c3', 5, 6, 0], ['e3', 5, 6, 0], ['g3', 5, 6, 0], ['c4', 5, 6, 0], ['e4', 5, 7, 0], ['c4', 5, 6, 5]]);
sf(9, 5, [['g3', 5, 5, 0], ['c4', 5, 5, 5]]);
sf(10, 5, [['c4', 5, 6, 0], ['e4', 5, 6, 0], ['g4', 5, 6, 5]]);
sf(11, 4, [['c3', 5, 6, 0], ['e3', 5, 6, 0], ['g3', 5, 6, 0], ['c4', 5, 6, 0],
['e4', 5, 7, 0], ['g4', 5, 7, 0], ['c5', 5, 7, 5]]);
sf(12, 8, [['c4', 4, 7, 6], ['c4', 4, 6, 6], ['c4', 4, 5, 5]]);
sf(13, 3, [['c4', 6, 3, 0], ['d4', 6, 3, 0], ['e4', 6, 2, 0]]);
sf(14, 4, [['c3', 7, 3, 1], ['g3', 7, 2, 5]]);
sf(15, 12, [['c2', 4, 2, 2], ['e2', 4, 2, 2]], 0, 2);
sf(16, 5, [['e3', 5, 5, 0], ['a3', 5, 5, 5]]);
sf(17, 4, [[0x30, 6, 4, 5], [0x20, 6, 3, 5], [0x10, 6, 2, 5]]);
sf(18, 14, [['a3', 5, 5, 0], ['f3', 5, 5, 0], ['e3', 5, 5, 0], ['a2', 5, 6, 5]]);
sf(19, 12, [['c4', 5, 6, 0], ['e4', 5, 6, 0], ['g4', 5, 6, 0], ['c5', 5, 7, 5]]);
sf(20, 6, [['c4', 4, 6, 0], ['e4', 4, 6, 0], ['g4', 4, 6, 0], ['a4', 4, 6, 0], ['c5', 4, 7, 5]]);
sf(21, 10, [['c3', 5, 6, 6], ['c3', 5, 6, 6], ['c4', 5, 7, 5]]);
sf(22, 2, [['a3', 3, 3, 0]]);

// --- music ----------------------------------------------------------
// chord tables: [root, third, fifth, seventh] as note names, low octave for bass
const CH = {
  am: ['a', 'c', 'e', 'g'], dm: ['d', 'f', 'a', 'c'], g: ['g', 'b', 'd', 'f'],
  c: ['c', 'e', 'g', 'b'], f: ['f', 'a', 'c', 'e'], e7: ['e', 'g#', 'b', 'd'],
};
// bass octave per chord root, chosen to keep the walk inside one register
const BOCT = { a: 1, d: 2, g: 1, c: 2, f: 1, e: 1, b: 1 };
const bassNote = n => n + BOCT[n[0]];
const upOct = (n, o) => n + o;

// An accompaniment part is written as two 16-step half-bars, one per chord.
// '1' '3' '5' '7' pick a chord tone (root third fifth seventh), '-' holds the note
// that is sounding (pico-8 joins identical consecutive notes into one
// sustained tone) and '.' is silence. The holds are what stop the parts
// machine-gunning: one note per beat that rings, not four that plink.
const h16 = x => { if (x.length !== 16) throw new Error('half-bar is ' + x.length + ' steps: ' + x); return x; };
function fig(c1, c2, pat, oct, wave, vol) {
  if (pat.length !== 32) throw new Error('figure is ' + pat.length + ' steps, want 32');
  const out = [];
  let last = null;
  for (let i = 0; i < 32; i++) {
    const t = CH[i < 16 ? c1 : c2], c = pat[i], iv = { 1: 0, 3: 1, 5: 2, 7: 3 }[c];
    if (c === '.') { last = null; out.push(null); }
    else if (c === '-') out.push(last ? [last, wave, vol, 0] : null);
    else {
      if (iv === undefined) throw new Error('bad step ' + c);
      last = typeof oct === 'function' ? oct(t[iv]) : upOct(t[iv], oct);
      out.push([last, wave, vol, 0]);
    }
  }
  return out;
}
// a lead line as [note|null, steps] pairs — 32 steps to the bar, the first 16
// over the first chord. long values and rests, not a stream of eighths.
function phrase(seq, wave, vol) {
  const out = [];
  for (const [n, d] of seq) for (let i = 0; i < d; i++) out.push(n ? [n, wave, vol, 0] : null);
  if (out.length !== 32) throw new Error('phrase is ' + out.length + ' steps, want 32');
  return out;
}

// walking bass, held quarters
const BS = [
  h16('1---5---3---5---'), h16('1---3---5---7---'),
  h16('1-------5---3---'), h16('1---5---7---5---'),
];
// harpsichord figure for the A section — broken chords with gaps in them
const AR = [
  h16('1--.5--.3--.5--.'), h16('1---5--.3-------'),
  h16('..1-3---5---3---'), h16('1---3---5---7---'),
];
// the B section answers on a soft triangle, longer values still
const BR = [
  h16('5---3---1-------'), h16('..3---1---5-----'),
  h16('1-------5---7---'), h16('3---5---7---5---'),
];
// off-beat comp: a pulse, not a drum roll
const CM = [
  h16('1.......5.3.....'), h16('..3.....1...5...'), h16('1.5.....3...7...'),
];

// A section lead. every bar has its own rhythm and at least one long note.
const MEL_A = [
  [['e4', 8], ['c4', 4], ['d4', 4], ['f4', 8], ['e4', 4], ['d4', 4]],
  [['d4', 4], ['e4', 2], ['d4', 2], ['b3', 8], ['c4', 6], ['e4', 2], ['g4', 8]],
  [[null, 4], ['a3', 4], ['c4', 8], ['b3', 4], ['g#3', 4], ['e4', 6], [null, 2]],
  [['e4', 6], ['d4', 2], ['c4', 4], ['b3', 4], ['a3', 8], ['b3', 4], ['e4', 4]],
];
// B section lead: same chords, higher register, even more air
const MEL_B = [
  [['a4', 8], ['g4', 4], ['e4', 4], ['f4', 12], ['d4', 4]],
  [['d4', 8], [null, 4], ['b3', 4], ['c4', 8], ['e4', 8]],
  [['c4', 6], ['a3', 2], ['f4', 8], ['b3', 8], ['g#3', 4], ['e4', 4]],
  [['e4', 4], ['c4', 4], ['b3', 8], ['g#3', 8], ['a3', 8]],
];
// last hand: the same bones, wound tighter
const MEL_L = [
  [['a3', 4], ['c4', 4], ['e4', 6], ['d4', 2], ['d4', 4], ['f4', 4], ['a4', 8]],
  [['g4', 8], ['d4', 4], ['b3', 4], ['c4', 4], ['e4', 4], ['g4', 8]],
  [['a3', 4], ['f4', 8], ['e4', 4], ['g#3', 4], ['b3', 4], ['e4', 8]],
  [['a3', 2], ['b3', 2], ['c4', 4], ['e4', 8], ['d4', 4], ['b3', 4], ['g#3', 4], ['a3', 4]],
];
// title screen: a slow statement of the same tune
const MEL_M = [
  [[null, 8], ['a3', 4], ['c4', 4], ['d4', 8], ['f4', 8]],
  [['c4', 4], ['a3', 4], ['f3', 8], ['b3', 8], ['e4', 8]],
];
const PROG = [['am', 'dm'], ['g', 'c'], ['f', 'e7'], ['am', 'e7']];
const SPD = 18;

// green felt, A section: patterns 8-11, sfx 28..43
PROG.forEach(([c1, c2], k) => {
  sf(28 + k, SPD, fig(c1, c2, BS[k] + BS[(k + 2) % 4], bassNote, 2, 5));
  sf(32 + k, SPD, fig(c1, c2, AR[k] + AR[(k + 1) % 4], 3, 4, 3));
  sf(36 + k, SPD, fig(c1, c2, CM[k % 2] + CM[k === 3 ? 2 : (k + 1) % 2], 2, 0, 2));
  sf(40 + k, SPD, phrase(MEL_A[k], 5, 4));
});
// B section: patterns 12-15, sfx 50..57. same chords, new lead and figure,
// and the comp drops out for its first half so the loop has a soft side.
PROG.forEach(([c1, c2], k) => {
  sf(50 + k, SPD, fig(c1, c2, BR[k] + BR[(k + 2) % 4], 3, 0, 3));
  sf(54 + k, SPD, phrase(MEL_B[k], 5, 4));
});
// last hand: patterns 20-23, sfx 58..61 over the A section backing
MEL_L.forEach((m, k) => sf(58 + k, SPD, phrase(m, 4, 5)));

// overture: free harpsichord then the bass joins. patterns 0-1, sfx 24..27, 62..63
sf(24, 20, fig('am', 'dm', AR[3] + AR[2], 3, 4, 3));
sf(25, 20, rest(32));
sf(26, 20, fig('f', 'e7', AR[1] + AR[3], 3, 4, 3));
sf(27, 20, fig('f', 'e7', BS[2] + BS[0], bassNote, 2, 5));
sf(62, 20, phrase(MEL_M[0], 5, 4));
sf(63, 20, phrase(MEL_M[1], 5, 4));

// payout / house wins jingles: patterns 24-25 and 28-29
sf(46, 16, phrase([['c4', 4], ['e4', 2], ['g4', 2], ['c5', 8], ['b4', 4], ['g4', 4], ['e4', 4], ['g4', 4]], 5, 6));
sf(47, 16, fig('c', 'g', BS[1] + BS[0], bassNote, 2, 5));
sf(48, 18, phrase([['a3', 4], ['e4', 4], ['c4', 4], ['a3', 4], ['g#3', 4], ['e3', 4], ['a3', 8]], 5, 5));
sf(49, 18, fig('am', 'e7', BS[0] + BS[2], bassNote, 2, 5));

for (let i = 0; i < 64; i++) if (!SFX[i]) SFX[i] = '01' + h2(16) + '0000' + '00000'.repeat(32);
SFX.forEach((l, i) => { if (l.length !== 168) throw new Error('sfx ' + i + ' = ' + l.length); });

// --- patterns --------------------------------------------------------
const MUS = [];
const pat = (i, flags, ch) => { MUS[i] = h2(flags) + ' ' + ch.map(c => h2(c === null ? 0x41 : c)).join(''); };
pat(0, 1, [25, 24, 62, null]);           // overture, loop start
pat(1, 2, [27, 26, 63, null]);           // loop end
pat(8, 1, [28, 32, 36, 40]);             // green felt, A section
pat(9, 0, [29, 33, 37, 41]);
pat(10, 0, [30, 34, 38, 42]);
pat(11, 0, [31, 35, 39, 43]);
pat(12, 0, [28, 50, null, 54]);          // B section: comp out, softer figure
pat(13, 0, [29, 51, null, 55]);
pat(14, 0, [30, 52, 38, 56]);            // comp back for the second half
pat(15, 2, [31, 53, 39, 57]);            // loop end, eight bars later
pat(20, 1, [28, 32, 36, 58]);            // last hand
pat(21, 0, [29, 33, 37, 59]);
pat(22, 0, [30, 34, 38, 60]);
pat(23, 2, [31, 35, 39, 61]);
pat(24, 0, [47, 46, null, null]);        // payout
pat(25, 4, [47, 46, null, null]);
pat(28, 0, [49, 48, null, null]);        // house wins
pat(29, 4, [49, 48, null, null]);
const maxpat = MUS.reduce((m, _, i) => i, 0);
for (let i = 0; i <= maxpat; i++) if (!MUS[i]) MUS[i] = '00 41424344';
MUS.forEach((l, i) => { if (l.length !== 11) throw new Error('music ' + i + ' = ' + l.length); });

// ---------------------------------------------------------------- splice
const cart = fs.readFileSync(CART, 'utf8');
const cut = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
if (cut < 0) throw new Error('no asset section in cart');
// keep the captured cart label if the cart already has one
const lab = cart.match(/^__label__\n(?:[0-9a-f]{128}\n)+/m);
const out = cart.slice(0, cut) +
  '__gfx__\n' + gfx.join('\n') + '\n' +
  (lab ? lab[0] : '') +
  '__sfx__\n' + SFX.join('\n') + '\n' +
  '__music__\n' + MUS.join('\n') + '\n';
fs.writeFileSync(CART, out);
console.log('gfx 128 lines, sfx ' + SFX.length + ', music ' + MUS.length + ' patterns -> ' + CART);
