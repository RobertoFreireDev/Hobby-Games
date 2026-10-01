// generates __gfx__ and the game's own __sfx__ slots for monstergram and
// splices them into game.p8.
//
// The splice is surgical on purpose: the cart also holds a hand-drawn
// __label__ and a __music__ bed whose instruments live in sfx 9..22. Only the
// __gfx__ body and the sfx slots this file actually defines are rewritten;
// every other line of the cart is passed through untouched.
const fs = require('fs');

// ---- 8x8 sprites: 8 rows of 8 chars, '.' = colour 0 (transparent when drawn)
const S = {};
S[1] = [ // unrevealed slab
"66666660",
"65555510",
"65555510",
"65555510",
"65555510",
"65555510",
"61111110",
"00000000"];
S[2] = [ // revealed floor (recessed)
"00000000",
"01111110",
"01111110",
"01111110",
"01111110",
"01111110",
"01111110",
"00000000"];
S[3] = [ // flag (drawn over slab)
"..8.....",
"..8888..",
"..88888.",
"..8888..",
"..8.....",
"..8.....",
".77777..",
"........"];
S[4] = [ // enemy l1 slime
"........",
"...bb...",
"..bbbb..",
".bbbbbb.",
".b1bb1b.",
".bbbbbb.",
".bb..bb.",
"........"];
S[5] = [ // enemy l2 bat
"........",
".e....e.",
".ee..ee.",
".eeeeee.",
".e1ee1e.",
".eeeeee.",
"..e..e..",
"........"];
S[6] = [ // enemy l3 demon
"........",
".8....8.",
".888888.",
".8a88a8.",
".888888.",
".878878.",
".888888.",
"..8..8.."];
S[7] = [ // skull / corpse
"........",
"..6666..",
".666666.",
".606606.",
".666666.",
".606606.",
"..6666..",
"........"];
S[8] = [ // weapon: sword
"...66...",
"...66...",
"...66...",
"...66...",
"...66...",
".999999.",
"...99...",
"...99..."];
S[9] = [ // shield
".cccccc.",
".cccccc.",
".c7777c.",
".cccccc.",
".cccccc.",
"..cccc..",
"...cc...",
"........"];
S[10] = [ // potion
"..6666..",
"...66...",
"...66...",
"..6666..",
".6eeee6.",
".6eeee6.",
".6eeee6.",
"..6666.."];
S[11] = [ // xp mote — drifts from a kill to the xp bar
"........",
"...bb...",
"..b77b..",
".b7777b.",
".b7777b.",
"..b77b..",
"...bb...",
"........"];

// ---- 16x16 effect animations, 4 frames each, drawn procedurally.
// A frame is a 16x16 char grid; frame f of an animation based at sprite `b`
// lands on the 2x2 sprite block b + f*2, so the game draws it with
// spr(b+f*2, x, y, 2, 2).
const N = 16, C = 7.5; // grid size, centre

const grid = () => Array.from({ length: N }, () => new Array(N).fill('.'));
const put = (g, x, y, c) => {
  x = Math.round(x); y = Math.round(y);
  if (x >= 0 && x < N && y >= 0 && y < N) g[y][x] = c;
};
// PICO-8 angles: 0..1 for a full turn, y down.
const px = a => Math.cos(a * 2 * Math.PI), py = a => Math.sin(a * 2 * Math.PI);
const dot = (g, a, r, c) => put(g, C + px(a) * r, C + py(a) * r, c);
const ray = (g, a, r0, r1, c) => { for (let r = r0; r <= r1; r += 0.5) dot(g, a, r, c); };
const ring = (g, r, c, keep) => {
  const n = Math.max(8, Math.round(r * 8));
  for (let i = 0; i < n; i++) { if (!keep || keep(i)) dot(g, i / n, r, c); }
};
const disc = (g, r, c) => {
  for (let y = -r; y <= r; y++) for (let x = -r; x <= r; x++) {
    if (x * x + y * y <= r * r) put(g, C + x, C + y, c);
  }
};

const A = {}; // name -> [4 grids]

// tile shatter: a slab cracking open into flying chunks
A.shatter = [0, 1, 2, 3].map(f => {
  const g = grid();
  const r = [2, 4.5, 6.5, 7.5][f], c = ['7', '6', '6', '5'][f];
  if (f === 0) disc(g, 2, '7'); else ring(g, r, c, i => (i * 5 + f) % 4 !== 0);
  if (f === 1) ring(g, r - 1.5, '7', i => i % 3 !== 0);
  for (let k = 0; k < 5; k++) { // chunks thrown clear of the ring
    const a = k / 5 + 0.06 * f, cr = r + 1 + f;
    dot(g, a, cr, ['6', '5', '5', '5'][f]);
    if (f < 3) dot(g, a + 0.02, cr, '5');
  }
  return g;
});

// item sparkle: a four-point star flashing open
A.sparkle = [0, 1, 2, 3].map(f => {
  const g = grid();
  const L = [2, 5, 7, 4][f], c = ['7', '10', '10', '9'][f];
  for (let k = 0; k < 4; k++) ray(g, k / 4, 0, L, c);
  for (let k = 0; k < 4; k++) ray(g, k / 4 + 0.125, 0, Math.max(1, L / 2 - 1), f < 2 ? '7' : '9');
  if (f < 3) disc(g, f === 0 ? 1 : 2, '7');
  for (let k = 0; k < 6; k++) if (f > 0) dot(g, k / 6 + 0.08 * f, L + 1, '10');
  return g;
});

// damage impact: a ragged red starburst
A.impact = [0, 1, 2, 3].map(f => {
  const g = grid();
  const L = [3, 6, 8, 8][f], c = ['7', '8', '8', '2'][f];
  for (let k = 0; k < 7; k++) {
    const a = k / 7 + 0.015 * f;
    ray(g, a, 1, L * (0.6 + ((k * 5) % 3) / 3), c);
  }
  if (f < 2) disc(g, 2 - f, f === 0 ? '7' : '9');
  if (f === 1) ring(g, 4, '9', i => i % 3 !== 0);
  return g;
});

// shield block: a hard blue bubble snapping outward
A.block = [0, 1, 2, 3].map(f => {
  const g = grid();
  const r = [2, 4, 6, 7.5][f], c = ['7', '12', '12', '1'][f];
  ring(g, r, c);
  if (f < 2) ring(g, r - 1, f === 0 ? '7' : '13', i => i % 2 === 0);
  if (f > 0) ring(g, r - 2, '13', i => i % 4 === 0);
  return g;
});

// level up: a green ring blooming out of the player
A.ring = [0, 1, 2, 3].map(f => {
  const g = grid();
  const r = [1.5, 3.5, 5.5, 7.5][f], c = ['7', '11', '11', '3'][f];
  ring(g, r, c);
  ring(g, r - 1, f < 2 ? '10' : '11', i => i % 2 === 0);
  if (f > 1) ring(g, r - 3, '3', i => i % 3 === 0);
  return g;
});

// sword swing: a bright streak travelling diagonally across the tile
A.slash = [0, 1, 2, 3].map(f => {
  const g = grid();
  const off = [-5, -1.5, 2, 5.5][f], c = ['7', '7', '6', '5'][f];
  // the streak runs along the "/" diagonal; `off` slides it along "\"
  for (let t = -8; t <= 8; t += 0.5) {
    const taper = 1 - Math.abs(t) / 9; // thins out at both ends
    if (taper <= 0) continue;
    const x = C + t * 0.707 + off * 0.707;
    const y = C - t * 0.707 + off * 0.707;
    put(g, x, y, c);
    if (f < 2 && taper > 0.45) put(g, x + 0.707, y + 0.707, f === 0 ? '7' : '6');
  }
  if (f < 3) for (let k = 0; k < 3; k++) { // sparks off the leading edge
    put(g, C + (5 - k) * 0.707 + (off + 2) * 0.707, C - (5 - k) * 0.707 + (off + 2) * 0.707, '10');
  }
  return g;
});

// base sprite index of each animation's first frame
const ANIM = { shatter: 32, sparkle: 40, impact: 64, block: 72, ring: 96, slash: 104 };

// ---- compose the sheet: 8 sprite rows = sprites 0..127 = 64 pixel lines.
// (Sprites 128..255 share memory with the map; nothing here goes near them.)
const ROWS = 8, H = ROWS * 8;
const sheet = Array.from({ length: H }, () => new Array(128).fill('0'));
const blit = (rows, n, w) => {
  const ox = (n % 16) * 8, oy = Math.floor(n / 16) * 8;
  if (rows.length !== w) throw new Error('sprite ' + n + ' bad height');
  rows.forEach((r, y) => {
    if (r.length !== w) throw new Error('sprite ' + n + ' row ' + y + ' bad width');
    for (let x = 0; x < w; x++) {
      const ch = r[x];
      if (oy + y >= H || ox + x >= 128) throw new Error('sprite ' + n + ' off sheet');
      sheet[oy + y][ox + x] = ch === '.' ? '0' : ch;
    }
  });
};
for (const k of Object.keys(S)) blit(S[k], +k, 8);
for (const name of Object.keys(ANIM)) {
  A[name].forEach((g, f) => {
    const b = ANIM[name] + f * 2;
    // a 16x16 grid whose cells may be two chars ("10") — flatten per row
    blit(g.map(row => row.map(c => (c === '.' ? '.' : parseInt(c, 10).toString(16)))), b, 16);
  });
}
const gfx = sheet.map(r => {
  const s = r.join('');
  if (s.length !== 128) throw new Error('gfx line width ' + s.length);
  return s;
});

// ---- sfx. Slots 9..22 are the music bed's instruments and are NOT touched.
function sfxline(speed, notes) {
  let s = '00' + speed.toString(16).padStart(2, '0') + '0000';
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    if (!n) { s += '00000'; continue; }
    s += n[0].toString(16).padStart(2, '0') + n[1].toString(16) + n[2].toString(16) + n[3].toString(16);
  }
  if (s.length !== 168) throw new Error('sfx width ' + s.length);
  return s;
}
const SFX = {
  0:  sfxline(6,  [[40,5,3,0],[36,5,2,5]]),                          // reveal blip
  1:  sfxline(6,  [[45,4,4,0],[50,4,3,0]]),                          // flag
  2:  sfxline(7,  [[36,5,5,0],[43,5,5,0],[48,5,6,0]]),               // pickup
  3:  sfxline(8,  [[28,6,6,3],[18,6,4,3]]),                          // hurt
  4:  sfxline(6,  [[26,3,5,0],[22,3,4,5]]),                          // blocked
  5:  sfxline(7,  [[40,5,4,0],[45,5,5,0],[52,5,6,0],[57,5,5,5]]),    // heal
  6:  sfxline(9,  [[36,5,5,0],[40,5,5,0],[43,5,5,0],[48,5,6,0],[0,0,0,0],[48,5,4,5]]), // floor clear
  7:  sfxline(14, [[24,2,6,0],[21,2,6,0],[17,2,6,0],[12,2,6,3]]),    // game over
  8:  sfxline(4,  [[38,6,7,3],[30,6,7,3],[22,6,6,3],[14,6,5,5]]),    // gear shatters
  23: sfxline(8,  [[45,5,4,0],[50,5,5,0],[54,5,6,0],[57,5,6,0],[62,5,7,0],[62,5,5,5]]), // level up fanfare
  24: sfxline(4,  [[55,5,2,0],[60,5,2,5]]),                          // xp mote lands
  25: sfxline(5,  [[14,6,4,0],[10,6,3,3],[6,6,2,5]]),                // slab crumbles
  26: sfxline(4,  [[52,2,3,0],[47,2,2,5]]),                          // cursor move
};

// ---- splice: rewrite the __gfx__ body, overwrite only the sfx slots above
const path = process.argv[2] || 'game.p8';
const lines = fs.readFileSync(path, 'utf8').replace(/\r\n/g, '\n').split('\n');
const mark = /^__(gfx|label|gff|map|sfx|music)__$/;
const sec = {};
lines.forEach((l, i) => { const m = l.match(mark); if (m) sec[m[1]] = i; });
if (sec.gfx === undefined || sec.sfx === undefined) throw new Error('cart is missing __gfx__ or __sfx__');

// body of a section = the lines after its marker, up to the next marker
const body = start => {
  let e = start + 1;
  while (e < lines.length && !mark.test(lines[e])) e++;
  return [start + 1, e];
};

// sfx first (later in the file, so the gfx splice below cannot shift it)
const [s0, s1] = body(sec.sfx);
const blank = sfxline(0, []);
const sfxBody = lines.slice(s0, s1).filter(l => l.trim() !== '');
const top = Math.max(...Object.keys(SFX).map(Number));
while (sfxBody.length <= top) sfxBody.push(blank);
for (const k of Object.keys(SFX)) sfxBody[+k] = SFX[k];
lines.splice(s0, s1 - s0, ...sfxBody);

const [g0, g1] = body(sec.gfx);
lines.splice(g0, g1 - g0, ...gfx);

fs.writeFileSync(path, lines.join('\n'));
console.log('wrote ' + gfx.length + ' gfx lines and sfx slots ' +
  Object.keys(SFX).join(',') + ' to ' + path +
  ' (label/music preserved: ' + (sec.label !== undefined) + '/' + (sec.music !== undefined) + ')');
