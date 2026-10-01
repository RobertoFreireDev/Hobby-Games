// gen.js — regenerates the __gfx__ and __sfx__ sections of triad's game.p8.
// Everything from __gfx__ onward is replaced; the __lua__ section is untouched.
// usage: node gen.js
const fs = require('fs');
const path = require('path');

const CART = path.join(__dirname, 'game.p8');

// ---------------------------------------------------------------- shapes
// 9 sprites: 3 shapes x 3 shadings, each 16x8 (2 tiles wide).
// Drawn in colour 7 so the game can pal(7, cardcolour) at draw time.

const W = 16, H = 8;

function inside(shape, x, y) {
  const px = x + 0.5, py = y + 0.5;
  const dx = px - W / 2, dy = py - H / 2;
  if (shape === 0) {                       // oval
    return (dx / 7.6) ** 2 + (dy / 3.7) ** 2 <= 1;
  }
  if (shape === 1) {                       // diamond
    return Math.abs(dx) / 7.9 + Math.abs(dy) / 3.95 <= 1;
  }
  // squiggle: a wavy band with rounded ends
  const v = dx / 8;                        // -0.97 .. 0.97
  const half = 2.35 * Math.sqrt(Math.max(0, 1 - v * v * 0.92));
  const mid = H / 2 + 1.55 * Math.sin((px / W) * Math.PI * 2);
  return Math.abs(py - mid) <= half;
}

function mask(shape) {
  const m = [];
  for (let y = 0; y < H; y++) {
    m.push([]);
    for (let x = 0; x < W; x++) m[y].push(inside(shape, x, y));
  }
  return m;
}

function isEdge(m, x, y) {
  const n = [[1, 0], [-1, 0], [0, 1], [0, -1]];
  for (const [dx, dy] of n) {
    const nx = x + dx, ny = y + dy;
    if (nx < 0 || nx >= W || ny < 0 || ny >= H || !m[ny][nx]) return true;
  }
  return false;
}

// shading: 0 solid, 1 striped, 2 open
function render(shape, shading) {
  const m = mask(shape);
  const out = [];
  for (let y = 0; y < H; y++) {
    let row = '';
    for (let x = 0; x < W; x++) {
      let on = false;
      if (m[y][x]) {
        if (shading === 0) on = true;
        else if (shading === 1) on = isEdge(m, x, y) || x % 2 === 0;
        else on = isEdge(m, x, y);
      }
      row += on ? '7' : '0';
    }
    out.push(row);
  }
  return out;
}

// sheet: 128x128, we only fill rows 8..23 (sprites 16..33)
const sheet = [];
for (let y = 0; y < 24; y++) sheet.push(new Array(128).fill('0'));

for (let shape = 0; shape < 3; shape++) {
  for (let shading = 0; shading < 3; shading++) {
    const n = 16 + (shape * 3 + shading) * 2;   // sprite index
    const sx = (n % 16) * 8;
    const sy = Math.floor(n / 16) * 8;
    const px = render(shape, shading);
    for (let y = 0; y < H; y++) {
      for (let x = 0; x < W; x++) sheet[sy + y][sx + x] = px[y][x];
    }
  }
}

const gfx = sheet.map(r => r.join(''));
gfx.forEach((l, i) => { if (l.length !== 128) throw new Error('gfx line ' + i + ' = ' + l.length); });

// ---------------------------------------------------------------- sfx
// note = [pitch, waveform, volume, effect]  (null = rest)
const R = null;
function line(speed, notes, loopS = 0, loopE = 0) {
  let s = '01' + hex(speed) + hex(loopS) + hex(loopE);
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    if (!n) { s += '00000'; continue; }
    s += hex(n[0]) + n[1].toString(16) + n[2].toString(16) + n[3].toString(16);
  }
  if (s.length !== 168) throw new Error('sfx length ' + s.length);
  return s;
}
function hex(v) { return v.toString(16).padStart(2, '0'); }

const sfx = [];
// 0 cursor tick
sfx[0] = line(4, [[36, 5, 3, 0], [40, 5, 2, 5]]);
// 1,2,3 rising arpeggio — the three selections
sfx[1] = line(6, [[28, 0, 5, 0], [28, 0, 3, 5]]);
sfx[2] = line(6, [[32, 0, 5, 0], [32, 0, 3, 5]]);
sfx[3] = line(6, [[35, 0, 5, 0], [35, 0, 4, 5]]);
// 4 deselect
sfx[4] = line(5, [[30, 5, 4, 0], [24, 5, 3, 5]]);
// 5 buzz
sfx[5] = line(8, [[12, 6, 5, 0], [10, 3, 5, 3], [7, 3, 4, 3], [5, 3, 3, 5]]);
// 6 chord resolution
sfx[6] = line(7, [[28, 4, 5, 0], [32, 4, 5, 0], [35, 4, 5, 0], [40, 4, 6, 0],
                  [40, 5, 5, 5], R, R, R]);
// 7 whoosh
sfx[7] = line(5, [[18, 6, 2, 4], [26, 6, 4, 0], [34, 6, 3, 5], [38, 6, 1, 5]]);
// 8 thud
sfx[8] = line(6, [[16, 0, 6, 3], [8, 0, 4, 5]]);
// 9 deal blip
sfx[9] = line(4, [[30, 2, 4, 0], [34, 2, 3, 5]]);
// 10 score ticker
sfx[10] = line(3, [[44, 5, 2, 0], [48, 5, 2, 5]]);
// 11 chain sparkle
sfx[11] = line(4, [[40, 5, 4, 0], [45, 5, 4, 0], [52, 5, 4, 5]]);
// 12 new record fanfare
sfx[12] = line(7, [[28, 3, 5, 0], [35, 3, 5, 0], [40, 3, 5, 0], [47, 3, 6, 0],
                   [44, 3, 5, 0], [47, 3, 6, 5], R, R]);
// 13 game over
sfx[13] = line(12, [[26, 0, 5, 0], [22, 0, 5, 0], [18, 0, 5, 0], [14, 0, 5, 0],
                    [10, 0, 4, 5], R, R, R]);

for (let i = 0; i < 14; i++) if (!sfx[i]) throw new Error('missing sfx ' + i);

// ---------------------------------------------------------------- music
// A minor: Am - F - C - G. Two voices, channels 0 and 1, reserved by the
// game with music(n,fade,3) so gameplay sfx always get channels 2 and 3.
// sfx 16..19 title bass   sfx 20..23 title arpeggio
// sfx 24..27 bed bass     sfx 28..31 bed pad
const CHORDS = [
  { bass: 21, arp: [33, 36, 40] },   // Am
  { bass: 17, arp: [29, 33, 36] },   // F
  { bass: 24, arp: [36, 40, 43] },   // C
  { bass: 19, arp: [31, 35, 38] },   // G
];

function bassNotes(root, vol, every) {
  const n = new Array(32).fill(R);
  for (let i = 0; i < 32; i += every) {
    // root, root, fifth, root
    const step = (i / every) % 4;
    n[i] = [step === 2 ? root + 7 : root, 0, vol, 5];
  }
  return n;
}

function arpNotes(arp, vol, every) {
  const n = new Array(32).fill(R);
  const seq = [arp[0], arp[1], arp[2], arp[1]];
  let k = 0;
  for (let i = 0; i < 32; i += every) {
    n[i] = [seq[k % 4], 5, vol, 5];
    k++;
  }
  return n;
}

CHORDS.forEach((c, i) => {
  sfx[16 + i] = line(18, bassNotes(c.bass, 4, 8));
  sfx[20 + i] = line(18, arpNotes(c.arp, 3, 2));
  // the in-game bed: slower, quieter, half as many events
  sfx[24 + i] = line(26, bassNotes(c.bass, 3, 16));
  sfx[28 + i] = line(26, arpNotes([c.arp[2], c.arp[1], c.arp[2] + 5], 2, 8));
});

const EMPTY = line(16, []);
for (let i = 0; i < 32; i++) if (!sfx[i]) sfx[i] = EMPTY;

// flags: 01 loop start, 02 loop end. 4x = channel off.
const music = [];
for (let i = 0; i < 4; i++) {          // 0..3 title theme
  const f = i === 0 ? '01' : i === 3 ? '02' : '00';
  music.push(f + ' ' + hex(16 + i) + hex(20 + i) + '4344');
}
for (let i = 0; i < 4; i++) {          // 4..7 gameplay bed
  const f = i === 0 ? '01' : i === 3 ? '02' : '00';
  music.push(f + ' ' + hex(24 + i) + hex(28 + i) + '4344');
}
music.forEach((l, i) => { if (l.length !== 11) throw new Error('music line ' + i); });

// ---------------------------------------------------------------- splice
// Rebuild the asset sections, but carry __label__ through untouched — it is
// produced by labelgen.p8 + label-tool.js, not here.
const cart = fs.readFileSync(CART, 'utf8');
const cut = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
if (cut < 0) throw new Error('no asset section marker in game.p8');

const tail = cart.slice(cut).split(/\r?\n/);
let label = null;
for (let i = 0; i < tail.length; i++) {
  if (tail[i] === '__label__') {
    const rows = [];
    for (let j = i + 1; j < tail.length && /^[0-9a-f]{128}$/.test(tail[j]); j++) rows.push(tail[j]);
    label = rows;
    break;
  }
}

// section order is fixed: __gfx__ __label__ __gff__ __map__ __sfx__ __music__
let out = cart.slice(0, cut) + '__gfx__\n' + gfx.join('\n') + '\n';
if (label) out += '__label__\n' + label.join('\n') + '\n';
out += '__sfx__\n' + sfx.join('\n') + '\n';
out += '__music__\n' + music.join('\n') + '\n';

fs.writeFileSync(CART, out);
console.log('gfx rows: ' + gfx.length + ', sfx slots: ' + sfx.length
  + ', music patterns: ' + music.length
  + ', label: ' + (label ? label.length + ' rows kept' : 'none'));

// ---------------------------------------------------------------- preview
const names = ['oval', 'diamond', 'squiggle'];
const shad = ['solid', 'striped', 'open'];
for (let shape = 0; shape < 3; shape++) {
  for (let shading = 0; shading < 3; shading++) {
    console.log('\n' + names[shape] + ' / ' + shad[shading]);
    for (const row of render(shape, shading)) {
      console.log('  ' + row.replace(/7/g, '#').replace(/0/g, '.'));
    }
  }
}
