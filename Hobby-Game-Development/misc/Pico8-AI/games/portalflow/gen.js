// gen.js — builds __gfx__, __sfx__ and __music__ for PORTAL FLOW.
// Keeps whatever is in __lua__ and __label__; rewrites everything else.
//   node gen.js            write the asset sections into game.p8
//   node gen.js preview    dump the tiles/logo as ascii art and the sfx as a table
'use strict';
const fs = require('fs');
const path = require('path');
const CART = path.join(__dirname, 'game.p8');
const PREVIEW = process.argv[2] === 'preview';
const CR = String.fromCharCode(13);

// ===================================================================== sheet
// 14 is the transparency key: the cart runs palt(14) / palt(0,false) so that
// colour 0 is available as a real outline on every sprite.
const T = 14;
const g = Array.from({ length: 128 }, () => new Array(128).fill(T));
const px = (x, y, c) => {
  if (x >= 0 && y >= 0 && x < 128 && y < 128 && c !== null) g[y][x] = c;
};
const dith = (x, y, a, b) => ((x + y) & 1 ? b : a);

// ------------------------------------------------------------- pipe shading
// Every pipe tile is the same solid: a fat stroke along a centreline, lit from
// the upper left. Authoring it as distance-to-a-polyline instead of by hand is
// what makes the straights, the elbow and the caps join seamlessly.
const R_BODY = 4.2, R_LINE = 5.2;
const LX = -Math.SQRT1_2, LY = -Math.SQRT1_2;

function nearest(p, s) {                      // closest point on segment s to p
  const [x1, y1, x2, y2] = s;
  const vx = x2 - x1, vy = y2 - y1;
  const l2 = vx * vx + vy * vy;
  let t = l2 ? ((p[0] - x1) * vx + (p[1] - y1) * vy) / l2 : 0;
  t = Math.max(0, Math.min(1, t));
  return [x1 + t * vx, y1 + t * vy];
}

// The silhouette is the distance to the nearest segment. The *lighting* is
// not: taking it from the nearest segment alone makes an elbow flip from
// "vertical pipe, shadow on the right" to "horizontal pipe, highlight on top"
// across the diagonal where nearest switches, which puts a hard seam through
// the bend. Blending the offset directions with a steep 1/d^4 weight instead


function pipeTile(tx, ty, segs, rb, rl) {
  rb = rb || R_BODY; rl = rl || R_LINE;
  for (let j = 0; j < 16; j++) for (let i = 0; i < 16; i++) {
    const p = [i + 0.5, j + 0.5];
    const off = [];
    let bd = 1e9;
    for (const s of segs) {
      const n = nearest(p, s);
      const dx = p[0] - n[0], dy = p[1] - n[1];
      const d = Math.hypot(dx, dy);
      if (d < bd) bd = d;
      off.push([dx, dy, d]);
    }
    if (bd >= rl) continue;
    if (bd >= rb) { px(tx + i, ty + j, 0); continue; }
    // the weight keys off how much *further* a segment is than the nearest,
    // not off absolute distance: 50/50 exactly on the diagonal where the two
    // are equal, under 0.3% once one is 1.5px closer. so an arm comes out
    // bit-identical to the matching straight and only the corner blends.
    let ax = 0, ay = 0, wsum = 0;
    for (const [dx, dy, d] of off) {
      if (d < 1e-6) continue;
      const w = Math.exp(-4 * (d - bd));
      ax += (dx / d) * w; ay += (dy / d) * w; wsum += w;
    }
    if (wsum > 0) { ax /= wsum; ay /= wsum; }
    const s = (ax * LX + ay * LY) * bd;
    let c;
    if (s > 1.9) c = 7;
    else if (s > 0.8) c = dith(i, j, 7, 6);
    else if (s > -1.1) c = 6;
    else if (s > -2.1) c = dith(i, j, 6, 5);
    else c = 5;
    px(tx + i, ty + j, c);
  }
}

// ------------------------------------------------------------------- tiles
// 16x16 tile t lives at sheet (t%8*16, t\8*16); its base sprite is t\8*32+t%8*2.
const tileXY = (t) => [(t % 8) * 16, Math.floor(t / 8) * 16];

// 0 — empty board tile: dark blue with a faint indigo weave and grid corners
{
  const [x, y] = tileXY(0);
  for (let j = 0; j < 16; j++) for (let i = 0; i < 16; i++) {
    let c = 1;
    if (i % 8 === 3 && j % 8 === 3) c = 13;
    if ((i === 0 || i === 15) && (j === 0 || j === 15)) c = 13;
    px(x + i, y + j, c);
  }
}
// 1 straight vertical, 2 straight horizontal, 3 elbow n-e, 4 cap n, 5 cap w.
// The elbow keeps a sharp centreline so both arms stay straight right up to
// the tile edge and line up with their neighbours; the corner is smoothed by
// the blended lighting in pipeTile, not by bending the path.
pipeTile(...tileXY(1), [[8, -3, 8, 19]]);
pipeTile(...tileXY(2), [[-3, 8, 19, 8]]);
pipeTile(...tileXY(3), [[8, -3, 8, 8], [8, 8, 19, 8]]);
pipeTile(...tileXY(4), [[8, -3, 8, 9]]);
pipeTile(...tileXY(5), [[-3, 8, 9, 8]]);
// The light is fixed at the upper left, so a flipped sprite carries its
// highlight to the wrong side: flip_x on the elbow puts the vertical arm's
// shadow on the left, flip_y puts the horizontal arm's highlight underneath.
// Every orientation therefore gets its own tile, generated from the same
// model, and pipe() never flips. 14/15 fill out row 1; 24..28 are row 3,
// which is clear of the 8x8 items in row 4 and of the shared map memory.
pipeTile(...tileXY(14), [[8, -3, 8, 8], [-3, 8, 8, 8]]);   // elbow n-w
pipeTile(...tileXY(15), [[8, 8, 8, 19], [8, 8, 19, 8]]);   // elbow s-e
pipeTile(...tileXY(24), [[8, 8, 8, 19], [-3, 8, 8, 8]]);   // elbow s-w
pipeTile(...tileXY(25), [[8, 7, 8, 19]]);                  // cap s
pipeTile(...tileXY(26), [[7, 8, 19, 8]]);                  // cap e

// 12/13 — portal tongues. Two failure modes to thread between: a full-width
// cap *under* the ring is completely hidden by it (the ring is as wide as the
// tile), so only a disconnected blob shows in the mouth and the portal reads
// as sitting on top of the pipe; a full-width stub *over* the ring hides the
// ring's near side and reads as the pipe hooking over it. So: narrow, drawn
// over the ring, running from the tile edge into the hole. The pipe visibly
// necks down and is pulled through.
const TONGUE_B = 2.6, TONGUE_L = 3.4;
pipeTile(...tileXY(12), [[8, -1, 8, 7]], TONGUE_B, TONGUE_L);
pipeTile(...tileXY(13), [[-1, 8, 7, 8]], TONGUE_B, TONGUE_L);
pipeTile(...tileXY(27), [[8, 9, 8, 17]], TONGUE_B, TONGUE_L);   // tongue s
pipeTile(...tileXY(28), [[9, 8, 17, 8]], TONGUE_B, TONGUE_L);   // tongue e

// 6 endpoint dot, 7 endpoint dot once its colour is connected
function dotTile(t, lit) {
  const [x, y] = tileXY(t);
  for (let j = 0; j < 16; j++) for (let i = 0; i < 16; i++) {
    const dx = i + 0.5 - 8, dy = j + 0.5 - 8;
    const r = Math.hypot(dx, dy);
    const rr = lit ? 5.4 : 6.2;
    if (r >= 7.2) continue;
    if (r >= 6.2) { px(x + i, y + j, 0); continue; }
    if (lit && r >= rr) { px(x + i, y + j, 7); continue; }  // locked-in rim
    const nx = dx / rr, ny = dy / rr;
    const nz = Math.sqrt(Math.max(0, 1 - nx * nx - ny * ny));
    const lam = nx * -0.5 + ny * -0.5 + nz * 0.7071;
    let c;
    if (lam > 0.86) c = 7;
    else if (lam > 0.66) c = dith(i, j, 7, 6);
    else if (lam > 0.32) c = 6;
    else if (lam > 0.08) c = dith(i, j, 6, 5);
    else c = 5;
    px(x + i, y + j, c);
  }
}
dotTile(6, false);
dotTile(7, true);

// 8..11 — portal, four rotation frames. The middle is left transparent so the
// pipe cap drawn underneath shows through the mouth.
for (let f = 0; f < 4; f++) {
  const [x, y] = tileXY(8 + f);
  for (let j = 0; j < 16; j++) for (let i = 0; i < 16; i++) {
    const dx = i + 0.5 - 8, dy = j + 0.5 - 8;
    const r = Math.hypot(dx, dy);
    if (r >= 7.8 || r < 4.0) continue;
    let c;
    if (r >= 7.1) c = 0;
    else if (r < 4.6) c = 0;
    else {
      // white spokes on indigo only: colour 6 would make the ring read as the
      // silver flow, and the portal must never look like a flow colour (8.1)
      const a = Math.atan2(dy, dx) / (Math.PI * 2);
      const b = Math.cos((a * 4 + f / 4) * Math.PI * 2);
      c = b > 0.35 ? 7 : 13;
      if (r > 6.4 && c === 7) c = dith(i, j, 7, 13);   // rim falls into shadow
    }
    px(x + i, y + j, c);
  }
}

// ------------------------------------------------------- 8x8 items, row 4
const sprXY = (n) => [(n % 16) * 8, Math.floor(n / 16) * 8];
function art8(n, rows, map) {
  const [x, y] = sprXY(n);
  rows.forEach((r, j) => [...r].forEach((ch, i) => {
    if (ch !== '.') px(x + i, y + j, map ? map[ch] : parseInt(ch, 16));
  }));
}

// colour-blind glyphs: colour is never the only channel on a dot (§8.1)
const GLYPHS = [
  ['.....', '.###.', '.###.', '.###.', '.....'],   // 1 square
  ['.###.', '#...#', '#...#', '#...#', '.###.'],   // 2 ring
  ['#...#', '.#.#.', '..#..', '.#.#.', '#...#'],   // 3 cross
  ['#####', '.....', '#####', '.....', '#####'],   // 4 bars
  ['.....', '#...#', '.#.#.', '..#..', '.....'],   // 5 chevron
  ['.....', '..#..', '.###.', '#####', '.....'],   // 6 triangle
  ['..#..', '.###.', '#####', '.###.', '..#..'],   // 7 diamond
];
GLYPHS.forEach((rows, k) => {
  const [x, y] = sprXY(64 + k);
  rows.forEach((r, j) => [...r].forEach((ch, i) => {
    if (ch === '#') px(x + 2 + i, y + 2 + j, 0);
  }));
});

art8(72, [                     // cursor bracket (top-left corner, flipped x3)
  '77777...',
  '70000...',
  '70......',
  '70......',
  '70......',
  '........',
  '........',
  '........']);
art8(73, [                     // star
  '..aa....',
  '..aa....',
  'aa77aaa.',
  '.a777a..',
  '..a7a...',
  '.aa.aa..',
  '.a...a..',
  '........']);
art8(74, [                     // padlock
  '..6666..',
  '.65..56.',
  '.65..56.',
  '6666666.',
  '6577756.',
  '6570756.',
  '6577756.',
  '.66666..']);

// --------------------------------------------------------------- the logo
// Hand-cut bold letterforms, 10 rows tall; only p o r t a l f w are needed.
const LETTERS = {
  p: ['########.', '########.', '##.....##', '##.....##', '########.',
      '########.', '##.......', '##.......', '##.......', '##.......'],
  o: ['.#######.', '##.....##', '##.....##', '##.....##', '##.....##',
      '##.....##', '##.....##', '##.....##', '##.....##', '.#######.'],
  r: ['########.', '##.....##', '##.....##', '##.....##', '########.',
      '##.###...', '##..###..', '##...###.', '##....###', '##.....##'],
  t: ['#########', '#########', '...###...', '...###...', '...###...',
      '...###...', '...###...', '...###...', '...###...', '...###...'],
  a: ['..#####..', '.##...##.', '##.....##', '##.....##', '#########',
      '#########', '##.....##', '##.....##', '##.....##', '##.....##'],
  l: ['##.......', '##.......', '##.......', '##.......', '##.......',
      '##.......', '##.......', '##.......', '#########', '#########'],
  f: ['#########', '#########', '##.......', '##.......', '########.',
      '########.', '##.......', '##.......', '##.......', '##.......'],
  w: ['##.......##', '##.......##', '##.......##', '##.......##', '##...#...##',
      '##..###..##', '##.##.##.##', '##.##.##.##', '#####.#####', '.###...###.'],
};
{
  const word = 'portal flow';
  const mask = [];                       // sparse fill mask, x -> Set(y)
  let cx = 1;
  for (const ch of word) {
    if (ch === ' ') { cx += 7; continue; }
    const L = LETTERS[ch];
    L.forEach((r, j) => [...r].forEach((c, i) => {
      if (c === '#') mask.push([cx + i, 1 + j]);
    }));
    cx += L[0].length + 1;
  }
  if (cx > 110) throw new Error('logo too wide: ' + cx);
  const has = new Set(mask.map(([x, y]) => x + ',' + y));
  const LX0 = 0, LY0 = 64;
  for (let j = 0; j < 16; j++) for (let i = 0; i < 112; i++) px(LX0 + i, LY0 + j, T);
  for (const [x, y] of mask) px(LX0 + x + 2, LY0 + y + 2, 13);       // shadow
  for (const [x, y] of mask)                                          // outline
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++)
      if (!has.has((x + dx) + ',' + (y + dy))) px(LX0 + x + dx, LY0 + y + dy, 1);
  for (const [x, y] of mask) px(LX0 + x, LY0 + y, 7);                 // fill
}

// ====================================================================== sfx
const STEP = { c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11 };
function pitch(s) {
  const m = /^([a-g])([#b]?)(\d)$/.exec(s);
  if (!m) throw new Error('bad note ' + s);
  const p = STEP[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0) + (+m[3]) * 12;
  if (p < 0 || p > 63) throw new Error('note out of range ' + s);
  return p;
}
const hex1 = (n) => n.toString(16);
const hex2 = (n) => (n & 0xff).toString(16).padStart(2, '0');

// A voice is 32 whitespace-separated slots: a note, "." for a rest, or "-" to
// hold. pico-8 has no note length, so a hold repeats the pitch — but at the
// same volume with effect 1 (slide), which slides from the previous note and
// therefore continues it seamlessly instead of re-attacking it. Retriggering
// a held bass note four times a second turns a pad into a pulse.
function voice(str, wave, vol, opt) {
  opt = opt || {};
  const toks = str.trim().split(/\s+/);
  if (toks.length !== 32) throw new Error('voice has ' + toks.length + ' slots: ' + str);
  let last = null, out = '';
  for (const t of toks) {
    if (t === '.') { out += '00000'; last = null; continue; }
    let p, v, e;
    if (t === '-') {
      if (last === null) throw new Error('hold with no note: ' + str);
      p = last; v = vol; e = 1;
    } else { p = pitch(t); v = vol; e = opt.fx || 0; last = p; }
    out += hex2(p) + hex1(wave) + hex1(v) + hex1(e);
  }
  return out;
}
const REST = voice(new Array(32).fill('.').join(' '), 0, 0);

const sfxLines = new Array(64).fill(null);
function put(n, speed, notes, loop) {
  const line = '01' + hex2(speed) + hex2(loop ? loop[0] : 0) + hex2(loop ? loop[1] : 0) + notes;
  if (line.length !== 168) throw new Error('sfx ' + n + ' is ' + line.length + ' chars');
  if (sfxLines[n]) throw new Error('sfx slot ' + n + ' used twice');
  sfxLines[n] = line;
}
// a short sound: list of [note|null, wave, vol, fx]
function short(n, speed, notes) {
  let s = '';
  for (let i = 0; i < 32; i++) {
    const e = notes[i];
    s += e ? hex2(pitch(e[0])) + hex1(e[1]) + hex1(e[2]) + hex1(e[3] || 0) : '00000';
  }
  put(n, speed, s);
}

//  0 cursor move — soft tick
short(0, 6, [['e4', 1, 2, 5]]);
//  1 pipe extend — 32 chromatic steps, played one note at a time with
//    sfx(1,3,#path,1) so a long pipe literally sings its way up (§10.1)
short(1, 10, Array.from({ length: 32 }, (_, i) =>
  [['c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'][i % 12] + (2 + ((i / 12) | 0)), 1, 3, 5]));
//  2 pipe retract — the same ladder, softer, played at the shorter index
short(2, 10, Array.from({ length: 32 }, (_, i) =>
  [['c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'][i % 12] + (2 + ((i / 12) | 0)), 0, 2, 5]));
//  3 grab dot — soft pluck
short(3, 8, [['g3', 3, 4, 5], ['c4', 3, 3, 5]]);
//  4 release — muted low pluck
short(4, 9, [['g2', 0, 3, 5]]);
//  5 colour connected — rising arpeggio
short(5, 8, [['c3', 1, 4, 0], ['e3', 1, 4, 0], ['g3', 1, 4, 5]]);
//  6 pipe truncated — warm falling pair, never harsh
short(6, 10, [['d3', 0, 3, 0], ['a2', 0, 3, 5]]);
//  7 portal enter — rising glissando with vibrato
short(7, 7, [['c2', 5, 4, 1], ['g2', 5, 4, 1], ['d3', 5, 4, 1], ['a3', 5, 3, 2]]);
//  8 portal exit — the same interval answered downward
short(8, 7, [['a3', 5, 4, 1], ['d3', 5, 4, 1], ['g2', 5, 4, 1], ['c2', 5, 3, 2]]);
//  9 illegal — quiet thud, must never read as a buzzer
short(9, 8, [['e1', 0, 2, 5]]);
// 10 all connected but the board is not full — questioning, not negative
short(10, 16, [['f3', 5, 3, 5], null, ['b2', 5, 3, 5]]);
// 11 level complete — five notes resolving to c
short(11, 11, [['g3', 1, 4, 0], ['a3', 1, 4, 0], ['b3', 1, 4, 0], ['d4', 1, 5, 0], ['c4', 1, 5, 5]]);
// 12 undo
short(12, 7, [['a3', 3, 3, 4], ['d3', 3, 3, 5]]);
// 13 clear board — descending sweep
short(13, 6, [['c4', 2, 4, 3], ['g3', 2, 4, 3], ['d3', 2, 3, 3], ['g2', 2, 3, 3], ['c2', 2, 2, 5]]);
// 14 menu move
short(14, 6, [['c4', 1, 2, 5]]);
// 15 menu select — clean fifth
short(15, 8, [['c3', 5, 4, 0], ['g3', 5, 4, 5]]);
// 16 menu back — the fifth inverted
short(16, 8, [['g3', 5, 4, 0], ['c3', 5, 4, 5]]);
// 17 level unlock — sparkle
short(17, 5, [['e4', 1, 4, 0], ['a4', 1, 4, 0], ['b4', 1, 4, 5]]);
// 18 star pop — single bell
short(18, 9, [['b4', 5, 4, 5]]);
// 19 card flip — papery tick
short(19, 5, [['a3', 3, 2, 5], ['d3', 3, 1, 5]]);

// ==================================================================== music
// 32 slots per pattern at speed 28 = two bars of 4/4 at ~64 bpm. Three voices:
// ch0 bass, ch1 pad (organ), ch2 melody. ch3 is left free for sfx, always.
const MSPD = 28;
const P = { bass: 0, pad: 5, mel: 1 };

// --- track a : gymnopedie sway, level select ---------------------- sfx 20-35
// bass, root on beats 1 and 3 of each bar
const A_BASS = {
  20: 'g1 - - - - - - - g1 - - - - - - - d1 - - - - - - - d1 - - - - - - -',
  21: 'e1 - - - - - - - e1 - - - - - - - c1 - - - - - - - c1 - - - - - - -',
  22: 'a1 - - - - - - - a1 - - - - - - - d1 - - - - - - - d1 - - - - - - -',
  23: 'g1 - - - - - - - g1 - - - - - - - g1 - - - - - - - g1 - - - - - - -',
};
const A_PAD = {
  24: '. . b2 - - - d3 - - - f#3 - - - d3 - . . a2 - - - d3 - - - f#3 - - - d3 -',
  25: '. . g2 - - - b2 - - - d3 - - - b2 - . . g2 - - - c3 - - - e3 - - - c3 -',
  26: '. . c3 - - - e3 - - - a3 - - - e3 - . . a2 - - - d3 - - - f#3 - - - d3 -',
  27: '. . b2 - - - d3 - - - g3 - - - d3 - . . b2 - - - d3 - - - g3 - - - b2 -',
};
const A_MEL = {
  28: '. . . . d3 - - - - - - - b2 - - - a2 - - - - - - - f#2 - - - - - - -',
  29: '. . . . e3 - - - - - - - d3 - - - b2 - - - - - - - c3 - - - - - - -',
  30: '. . . . g3 - - - d3 - - - b2 - - - a2 - - - b2 - - - a2 - - - - - - -',
  31: '. . . . c3 - - - - - - - a2 - - - b2 - - - - - - - a2 - - - - - - -',
  32: '. . . . . . . . d3 - - - - - - - . . . . f#2 - - - - - - - a2 - - -',
  33: '. . . . g3 - - - - - - - e3 - - - . . . . d3 - - - - - - - c3 - - -',
  34: '. . . . e3 - - - d3 - - - c3 - - - b2 - - - - - - - a2 - - - - - - -',
  35: '. . . . b2 - - - - - - - d3 - - - g2 - - - - - - - - - - - - - - -',
};

// --- track b : bwv 846 broken chords, levels 1-8 ------------------ sfx 36-49
// each bar is (bass bass upper upper upper upper upper upper) x2, sixteenths
const BACH = [
  ['c2', 'e2', 'g2', 'c3', 'e3'],   // 1 c
  ['c2', 'd2', 'a2', 'd3', 'f3'],   // 2 dm7/c
  ['b1', 'd2', 'g2', 'd3', 'f3'],   // 3 g7/b
  ['c2', 'e2', 'g2', 'c3', 'e3'],   // 4 c
  ['c2', 'e2', 'a2', 'e3', 'a3'],   // 5 am7
  ['c2', 'd2', 'f#2', 'a2', 'd3'],  // 6 d7/c
  ['b1', 'd2', 'g2', 'd3', 'g3'],   // 7 g
  ['b1', 'c2', 'e2', 'g2', 'c3'],   // 8 c/b
];
function bachBar(h, thin) {
  const [b1, b2, a1, a2, a3] = h;
  const half = [b1, b2, a1, a2, a3, a1, a2, a3];
  return thin ? half.concat(['.', '.', '.', '.', '.', '.', '.', '.'])
              : half.concat(half);
}
const B_MEL = {};
for (let i = 0; i < 4; i++) {
  B_MEL[36 + i] = bachBar(BACH[i * 2], false).concat(bachBar(BACH[i * 2 + 1], false)).join(' ');
  B_MEL[40 + i] = bachBar(BACH[i * 2], true).concat(bachBar(BACH[i * 2 + 1], true)).join(' ');
}
const B_BASS = {
  44: 'c1 - - - - - - - - - - - - - - - c1 - - - - - - - - - - - - - - -',
  45: 'b0 - - - - - - - - - - - - - - - c1 - - - - - - - - - - - - - - -',
  46: 'b0 - - - - - - - - - - - - - - - b0 - - - - - - - - - - - - - - -',
  47: 'g0 - - - - - - - - - - - - - - - c1 - - - - - - - - - - - - - - -',
};
const B_PAD = {
  48: '. . . . . . . . e3 - - - - - - - . . . . . . . . f3 - - - - - - -',
  49: '. . . . . . . . d3 - - - - - - - . . . . . . . . e3 - - - - - - -',
};

// --- track c : a minor, wistful, levels 9-16 ---------------------- sfx 50-63
const C_MEL = {
  50: '. . . . a3 - - - - - g#3 - - - - - b3 - - - - - a3 - - - - - - - - -',
  51: '. . . . e3 - - - - - f3 - - - - - e3 - - - - - - - - - - - - - - -',
  52: '. . . . c4 - - - - - b3 - - - - - a3 - - - - - g#3 - - - - - - - - -',
  53: '. . . . a3 - - - - - - - - - - - e3 - - - - - - - - - - - - - - -',
  54: '. . . . d4 - - - - - c4 - - - - - b3 - - - - - a3 - - - - - - - - -',
  55: '. . . . f3 - - - - - e3 - - - - - d3 - - - - - c3 - - - - - - - - -',
  56: '. . . . b3 - - - - - - - c4 - - - b3 - - - - - g#3 - - - - - - - - -',
  57: '. . . . a3 - - - - - - - - - - - a2 - - - - - - - - - - - - - - -',
};
const C_BASS = {
  58: 'a0 - - - - - - - e1 - - - - - - - e0 - - - - - - - b0 - - - - - - -',
  59: 'a0 - - - - - - - e1 - - - - - - - d1 - - - - - - - a1 - - - - - - -',
  60: 'f0 - - - - - - - c1 - - - - - - - e0 - - - - - - - b0 - - - - - - -',
};
const C_PAD = {
  61: '. . . . c3 - - - e3 - - - a3 - - - . . . . b2 - - - e3 - - - g#3 - - -',
  62: '. . . . d3 - - - f3 - - - a3 - - - . . . . c3 - - - e3 - - - a3 - - -',
  63: '. . . . c3 - - - f3 - - - a3 - - - . . . . b2 - - - e3 - - - g#3 - - -',
};

for (const [n, s] of Object.entries(A_BASS)) put(+n, MSPD, voice(s, P.bass, 4));
for (const [n, s] of Object.entries(A_PAD)) put(+n, MSPD, voice(s, P.pad, 3));
for (const [n, s] of Object.entries(A_MEL)) put(+n, MSPD, voice(s, P.mel, 4));
for (const [n, s] of Object.entries(B_MEL)) put(+n, MSPD, voice(s, P.mel, 4));
for (const [n, s] of Object.entries(B_BASS)) put(+n, MSPD, voice(s, P.bass, 4));
for (const [n, s] of Object.entries(B_PAD)) put(+n, MSPD, voice(s, P.pad, 3));
for (const [n, s] of Object.entries(C_MEL)) put(+n, MSPD, voice(s, P.mel, 4));
for (const [n, s] of Object.entries(C_BASS)) put(+n, MSPD, voice(s, P.bass, 4));
for (const [n, s] of Object.entries(C_PAD)) put(+n, MSPD, voice(s, P.pad, 3));

// pattern table: [flags, ch0 bass, ch1 pad, ch2 melody]; ch3 stays free
const OFF = 0x43;
const PAT = [
  // track a — select screen, loops 0..7
  [1, 20, 24, 28], [0, 21, 25, 29], [0, 20, 26, 30], [0, 22, 27, 31],
  [0, 20, 24, 32], [0, 21, OFF, 33], [0, 22, 26, 34], [2, 23, 27, 35],
  // track b — levels 1-8, loops 8..15
  [1, 44, OFF, 36], [0, 45, 48, 37], [0, 44, OFF, 38], [0, 46, 49, 39],
  [0, 44, 48, 40], [0, 45, OFF, 41], [0, 44, 49, 42], [2, 47, OFF, 43],
  // track c — levels 9-16, loops 16..23
  [1, 58, OFF, 50], [0, 59, 61, 51], [0, 58, OFF, 52], [0, 60, 62, 53],
  [0, 59, 63, 54], [0, 58, OFF, 55], [0, 60, 61, 56], [2, 58, OFF, 57],
];
const musicLines = PAT.map(([f, a, b, c]) =>
  hex2(f) + ' ' + hex2(a) + hex2(b) + hex2(c) + '44');

// ==================================================================== write
function section(cart, name) {
  const re = new RegExp('^__' + name + '__$', 'm');
  const m = re.exec(cart);
  if (!m) return null;
  const from = m.index + m[0].length + 1;
  const nx = cart.slice(from).search(/^__[a-z]+__$/m);
  return cart.slice(from, nx < 0 ? cart.length : from + nx);
}

const gfxLines = g.map((row) => row.map((c) => c.toString(16)).join(''));
for (const l of gfxLines) if (l.length !== 128) throw new Error('gfx line width ' + l.length);
for (const l of sfxLines) if (l && l.length !== 168) throw new Error('sfx line width');
const EMPTY = '01' + hex2(MSPD) + '0000' + REST;
const sfxOut = sfxLines.map((l) => l || EMPTY);
if (sfxLines.some((l) => !l)) console.error('warning: unused sfx slots');

if (PREVIEW) {
  const ramp = ' .:-=+*#%@$1234';
  const show = (x0, y0, w, h) => {
    for (let j = 0; j < h; j++) {
      let s = '';
      for (let i = 0; i < w; i++) {
        const c = g[y0 + j][x0 + i];
        s += c === T ? ' ' : c.toString(16);
      }
      console.log(s);
    }
  };
  for (const t of [...Array(14).keys(), 14, 15, 24, 25, 26, 27, 28]) {
    console.log('--- tile ' + t + ' (sprite ' + (Math.floor(t / 8) * 32 + (t % 8) * 2) + ')');
    show(...tileXY(t), 16, 16);
  }
  console.log('--- logo');
  show(0, 64, 112, 16);
  console.log('--- sfx slots used: ' + sfxLines.filter(Boolean).length + '/64');
  console.log('--- music patterns: ' + musicLines.length);
  process.exit(0);
}

let cart = fs.existsSync(CART) ? fs.readFileSync(CART, 'utf8').split(CR).join('')
  : 'pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n-- portal flow\n-- by roberto freire\n';
const lua = section(cart, 'lua');
const label = section(cart, 'label');
let out = 'pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n' + (lua || '');
if (!out.endsWith('\n')) out += '\n';
out += '__gfx__\n' + gfxLines.join('\n') + '\n';
if (label) out += '__label__\n' + label.replace(/\n*$/, '\n');
out += '__sfx__\n' + sfxOut.join('\n') + '\n';
out += '__music__\n' + musicLines.join('\n') + '\n';
fs.writeFileSync(CART, out);
console.log('game.p8 assets written: 128 gfx lines, ' +
  sfxLines.filter(Boolean).length + ' sfx, ' + musicLines.length + ' music patterns');
