// spritegen.js — generates the __gfx__ section of game.p8 and splices it in.
// See snake-pico8-guide.md §6 (art style) and §6.6 (sprite index layout).
//
//   node spritegen.js
//
// Every piece is one 16x16 tile = a 2x2 block of PICO-8 sprites, drawn with
// spr(n,x,y,2,2). Art is written here as ASCII *materials*, not colours: the
// script resolves them per piece and bakes the dither in, so the fillp() calls
// disappear from the draw path (§6.2 — safe because tiles are 16 px and pieces
// only ever move a whole tile, so a baked 4x4 pattern lands identically in
// every cell and never crawls).

const fs = require('fs');
const CART = 'game.p8';

// ---------- dither patterns (§6.2) ----------
// 16 bits, bit 15 = top-left, row-major. A 1 bit takes the dither colour.
const DITH_25 = 0b1010000010100000;
const DITH_50 = 0b1010010110100101;

const ditherBit = (pat, x, y) => (pat >> (15 - ((y % 4) * 4 + (x % 4)))) & 1;

// ---------- materials ----------
// .  transparent    o  outline (0)      #  base fill, dithered
// h  highlight      d  shadow           e/p  eye white / pupil
// w  accent 1       W  accent 2         m  mortar
// the key is the one colour no piece may contain. it used to be 14, and the
// pink tail took that away: 2 is now the only ink no sprite paints in — the
// board draws its grid lines and its minimap free tiles in it, but both with
// line()/rectfill(), which palt() does not touch. the assert below is what
// stops the next palette edit from silently punching holes in a piece.
const KEY = 2;
const INK = 0;      // one outline colour, globally (§6.1)
const SHADE = 4;    // ...and one shadow colour. A shadow drawn in the piece's own
                    // dark companion vanishes into its dither; brown is darker
                    // than every base pair and keeps the set reading as a set.

// ---------- the pieces ----------
// head, facing right. flip_x gives left; the vertical head is a separate tile.
const HEAD_H = [
  '..oooooooooooo..',
  '.ohhhhhhhhhhhho.',
  'ohhhhhhhhhhhhhdo',
  'oh############do',
  'oh########ep##do',
  'oh########pp##do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh########ep##do',
  'oh########pp##do',
  'oh############do',
  'oddddddddddddddo',
  '.oddddddddddddo.',
  '..oooooooooooo..',
];

// head, facing down. flip_y gives up.
const HEAD_V = [
  '..oooooooooooo..',
  '.ohhhhhhhhhhhho.',
  'ohhhhhhhhhhhhhdo',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh##ep####ep##do',
  'oh##pp####pp##do',
  'oh############do',
  'oddddddddddddddo',
  '.oddddddddddddo.',
  '..oooooooooooo..',
];

// body: a plain bevelled block. Anything drawn inside it competes with the
// 50% checker and reads as noise — the head carries the personality.
const BODY = [
  '..oooooooooooo..',
  '.ohhhhhhhhhhhho.',
  'ohhhhhhhhhhhhhdo',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oh############do',
  'oddddddddddddddo',
  '.oddddddddddddo.',
  '..oooooooooooo..',
];

// tail: the same block, two pixels narrower on every side, and pink rather
// than a second green. Direction is not encoded — the taper alone says "this
// end is the end", and the tail has no facing the way the head does. The
// 25 % dither is deliberate: at 50 % a two-colour checker reads the same
// whichever of the two is nominally the fill, so the tail would lose the
// ramp position that makes it read as *lit* rather than merely different.
const TAIL = [
  '................',
  '................',
  '....oooooooo....',
  '...ohhhhhhhho...',
  '..ohhhhhhhhhdo..',
  '..oh########do..',
  '..oh########do..',
  '..oh########do..',
  '..oh########do..',
  '..oh########do..',
  '..oh########do..',
  '..oddddddddddo..',
  '...oddddddddo...',
  '....oooooooo....',
  '................',
  '................',
];

// food: a red block with a glowing core, straight up the 8-9-10-15 ramp
const FOOD = [
  '..oooooooooooo..',
  '.ohhhhhhhhhhhho.',
  'ohhhhhhhhhhhhhdo',
  'oh############do',
  'oh###wwwwww###do',
  'oh##wwWWWWww##do',
  'oh##wWWWWWWw##do',
  'oh##wWWWWWWw##do',
  'oh##wWWWWWWw##do',
  'oh##wWWWWWWw##do',
  'oh##wwWWWWww##do',
  'oh###wwwwww###do',
  'oh############do',
  'oddddddddddddddo',
  '.oddddddddddddo.',
  '..oooooooooooo..',
];

// door: a recessed dark panel, so the white destination letter printed on top
// of it keeps its contrast (§6.5 — letter in 7)
const DOOR = [
  '..oooooooooooo..',
  '.ohhhhhhhhhhhho.',
  'ohhhhhhhhhhhhhdo',
  'oh############do',
  'oh##oooooooo##do',
  'oh##oWWWWWWo##do',
  'oh##oWWWWWWo##do',
  'oh##oWWWWWWo##do',
  'oh##oWWWWWWo##do',
  'oh##oWWWWWWo##do',
  'oh##oWWWWWWo##do',
  'oh##oooooooo##do',
  'oh############do',
  'oddddddddddddddo',
  '.oddddddddddddo.',
  '..oooooooooooo..',
];

// wall: running-bond brick. Grey plus the mortar courses is what stops it
// reading as another body segment (§6.5).
const WALL = [
  '..oooooooooooo..',
  '.ohhhhhhhhhhhho.',
  'oh#####m######do',
  'oh#####m######do',
  'oh#####m######do',
  'ommmmmmmmmmmmmmo',
  'oh##m######m##do',
  'oh##m######m##do',
  'oh##m######m##do',
  'oh##m######m##do',
  'ommmmmmmmmmmmmmo',
  'oh#####m######do',
  'oh#####m######do',
  'oddddddddddddddo',
  '.oddddddddddddo.',
  '..oooooooooooo..',
];

// index -> art + palette. Indices leave the 2x2 gaps §6.6 asks for:
// n consumes n, n+1, n+16, n+17.
const PIECES = [
  { name: 'head_h', idx: 1,  art: HEAD_H, fill: 10, dith: 9,  pat: DITH_25, h: 15, d: SHADE },
  { name: 'body',   idx: 3,  art: BODY,   fill: 11, dith: 3,  pat: DITH_50, h: 11, d: SHADE },
  { name: 'food',   idx: 5,  art: FOOD,   fill: 8,  dith: 9,  pat: DITH_25, h: 9,  d: SHADE, w: 10, W: 15 },
  { name: 'door',   idx: 7,  art: DOOR,   fill: 13, dith: 12, pat: DITH_50, h: 12, d: SHADE, W: 1 },
  { name: 'wall',   idx: 9,  art: WALL,   fill: 5,  dith: 6,  pat: DITH_25, h: 6,  d: SHADE, m: 0 },
  { name: 'head_v', idx: 11, art: HEAD_V, fill: 10, dith: 9,  pat: DITH_25, h: 15, d: SHADE },
  // pink, up the 2-8-14-15 ramp: fill 14, a quarter of 8 through it, 15 along
  // the lit edge. 2 is not available as its dark companion — it is the key
  { name: 'tail',   idx: 13, art: TAIL,   fill: 14, dith: 8,  pat: DITH_25, h: 15, d: SHADE },
];

// no piece may paint in the key colour, or palt() turns those pixels into
// holes. this is exactly the way a pink tail breaks while 14 is the key
for (const p of PIECES) {
  for (const k of ['fill', 'dith', 'h', 'd', 'w', 'W', 'm']) {
    if (p[k] === KEY) throw new Error(p.name + ': ' + k + ' is the key colour ' + KEY);
  }
}

function resolve(p, ch, x, y) {
  let c;
  switch (ch) {
    case '.': c = KEY; break;
    case 'o': c = INK; break;
    case '#': c = ditherBit(p.pat, x, y) ? p.dith : p.fill; break;
    case 'h': c = p.h; break;
    case 'd': c = p.d; break;
    case 'e': c = 7; break;
    case 'p': c = 0; break;
    case 'w': c = p.w; break;
    case 'W': c = p.W; break;
    case 'm': c = p.m; break;
    default: throw new Error(p.name + ": unknown material '" + ch + "'");
  }
  if (c === undefined) throw new Error(p.name + ": material '" + ch + "' has no colour");
  return c;
}

// ---------- rasterise ----------
const sheet = Array.from({ length: 128 }, () => Array(128).fill(0));

for (const p of PIECES) {
  if (p.art.length !== 16) throw new Error(p.name + ': ' + p.art.length + ' rows, want 16');
  p.art.forEach((row, y) => {
    if (row.length !== 16) {
      throw new Error(p.name + ' row ' + y + ': ' + row.length + ' chars, want 16 — "' + row + '"');
    }
  });
  // sprite n sits at sheet (n%16)*8, flr(n/16)*8
  const sx = (p.idx % 16) * 8, sy = Math.floor(p.idx / 16) * 8;
  if (sx + 16 > 128 || sy + 16 > 128) throw new Error(p.name + ': 2x2 block runs off the sheet');
  for (let y = 0; y < 16; y++) {
    for (let x = 0; x < 16; x++) sheet[sy + y][sx + x] = resolve(p, p.art[y][x], x, y);
  }
}

// trailing all-zero lines are legal to omit; keep only what the pieces reach
let used = 0;
sheet.forEach((line, y) => { if (line.some(c => c !== 0)) used = y + 1; });

const lines = sheet.slice(0, used).map((line, y) => {
  const s = line.map(c => c.toString(16)).join('');
  if (s.length !== 128) throw new Error('gfx line ' + y + ': ' + s.length + ' digits, want 128');
  return s;
});

// ---------- splice ----------
const cart = fs.readFileSync(CART, 'utf8');
const block = '__gfx__\n' + lines.join('\n') + '\n';
let out;
if (/^__gfx__$/m.test(cart)) {
  out = cart.replace(/^__gfx__\n(?:[0-9a-f]*\n)*/m, block);
} else {
  // section order: __gfx__ goes immediately after __lua__
  const i = cart.search(/^__(label|gff|map|sfx|music)__$/m);
  if (i < 0) throw new Error('no asset section found to insert before');
  out = cart.slice(0, i) + block + cart.slice(i);
}
fs.writeFileSync(CART, out);

console.log('wrote __gfx__: ' + lines.length + ' lines, ' + PIECES.length + ' pieces');
for (const p of PIECES) console.log('  ' + p.name.padEnd(7) + ' spr(' + p.idx + ',x,y,2,2)');
