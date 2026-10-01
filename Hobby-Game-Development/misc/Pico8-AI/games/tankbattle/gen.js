// gen.js — regenerates every asset section of games/tankbattle/game.p8
// (__gfx__, __gff__, __map__, __sfx__, __music__). The __lua__ section is kept.
// run: node games/tankbattle/gen.js
'use strict';
const fs = require('fs');
const path = require('path');
const CART = path.join(__dirname, 'game.p8');

const h1 = n => n.toString(16);
const h2 = n => n.toString(16).padStart(2, '0');

// ---------------------------------------------------------------- sprite sheet
// 128x128 pixels, colour 15 (peach) is the transparent colour (palt(15,true)).
const sheet = [];
for (let y = 0; y < 128; y++) sheet.push(new Array(128).fill(15));

function put(n, rowsArt, map) {
  const sx = (n % 16) * 8, sy = Math.floor(n / 16) * 8;
  if (rowsArt.length !== 8) throw new Error('sprite ' + n + ' rows');
  rowsArt.forEach((r, j) => {
    if (r.length !== 8) throw new Error('sprite ' + n + ' width row ' + j);
    for (let i = 0; i < 8; i++) {
      let ch = r[i];
      if (map && map[ch] !== undefined) ch = map[ch];
      sheet[sy + j][sx + i] = ch === '.' ? 15 : parseInt(ch, 16);
    }
  });
}

// --- tiles ---
put(16, [ // brick
  '49494949', '94949494', '22222222', '94949494',
  '49494949', '22222222', '49494949', '94949494']);
put(17, [ // cracked brick
  '49494949', '94049494', '22202222', '94940494',
  '49004949', '22220222', '49494049', '94949494']);
put(18, [ // steel
  '77777776', '76666665', '76767665', '76666665',
  '76667665', '76666665', '76666665', '65555555']);
put(20, [ // water
  '11111111', '1cc11cc1', 'c11cc11c', '11111111',
  '11111111', 'c11cc11c', '1cc11cc1', '11111111']);
put(22, [ // bush
  '.3b3..b.', '3bbb3bb3', 'bb3bbb3b', '3bbb33bb',
  '.b3bbb3.', '3bb3bb33', 'b3bbb3b.', '.3.b3.3.']);
put(24, [ // spawner marker
  '5......5', '.5....5.', '..8..8..', '........',
  '........', '..8..8..', '.5....5.', '5......5']);

// --- tank template: B body, T tread, O outline/tread dark, P rear pip ---
const tankUp = [
  '...OO...', '...OO...', 'OTBBBBTO', 'TOBBBBOT',
  'OTBBBBTO', 'TOBPPBOT', 'OTBBBBTO', 'TO....OT'];
const tankRight = [
  'OTOTOTOT', 'TOTOTOTO', '.BBBBBB.', '.BBBBBOO',
  '.PBBBBOO', '.BBBBBB.', 'OTOTOTOT', 'TOTOTOTO'];
const shiftTreads = rows => rows.map(r => r.replace(/[OT]/g, c => (c === 'O' ? 'T' : 'O')));
function tank(n, body, tread, pip) {
  const m = { B: body, T: tread, O: '0', P: pip };
  put(n, tankUp, m); put(n + 1, shiftTreads(tankUp), m);
  put(n + 2, tankRight, m); put(n + 3, shiftTreads(tankRight), m);
}
tank(32, '9', '4', '9'); // grunt  orange
tank(36, 'e', '2', 'e'); // runner pink
tank(40, 'c', '1', 'c'); // gunner blue
tank(44, '8', '4', '4'); // armor  red with brown plating (plating = 4, remapped by hp)
tank(48, 'b', '3', '7'); // player green, white pip

// armor plating: ring of 4 over the body
for (const n of [44, 45, 46, 47]) {
  const sx = (n % 16) * 8, sy = Math.floor(n / 16) * 8;
  for (let j = 2; j < 6; j++) for (let i = 2; i < 6; i++)
    if ((i === 2 || i === 5 || j === 2 || j === 5) && sheet[sy + j][sx + i] === 8) sheet[sy + j][sx + i] = 4;
}

// boss: template scaled 2x into a 16x16 block. up at 68 (68,69,84,85), right at 72.
function bigTank(n, rows, m) {
  const sx = (n % 16) * 8, sy = Math.floor(n / 16) * 8;
  for (let j = 0; j < 8; j++) for (let i = 0; i < 8; i++) {
    let ch = rows[j][i]; if (m[ch] !== undefined) ch = m[ch];
    const v = ch === '.' ? 15 : parseInt(ch, 16);
    for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) sheet[sy + j * 2 + dy][sx + i * 2 + dx] = v;
  }
  // plating dither on the body edge
  for (let j = 0; j < 16; j++) for (let i = 0; i < 16; i++)
    if (sheet[sy + j][sx + i] === 13 && (i + j) % 2 === 0 &&
        (j < 5 || j > 10 || i < 5 || i > 10)) sheet[sy + j][sx + i] = 2;
}
bigTank(68, tankUp, { B: 'd', T: '2', O: '0', P: '8' });
bigTank(72, tankRight, { B: 'd', T: '2', O: '0', P: '8' });

// --- muzzle flash 64,65,66 (big -> small), spark 67 ---
put(64, ['...7....', '.7.7.7..', '..aaa...', '7aa7aa7.', '..aaa...', '.7.7.7..', '...7....', '........']);
put(65, ['........', '...7....', '..a9a...', '.7a7a7..', '..a9a...', '...7....', '........', '........']);
put(66, ['........', '........', '...7....', '..797...', '...7....', '........', '........', '........']);
put(67, ['........', '...7....', '........', '.7.7.7..', '........', '...7....', '........', '........']);

// --- explosion 80..84: expanding then fading rings with dithered fringe ---
const boomFrames = [
  { r: 1.5, c: ['7', '7'] }, { r: 2.5, c: ['a', '7'] }, { r: 3.5, c: ['9', 'a'] },
  { r: 3.8, c: ['8', '9'] }, { r: 3.8, c: ['5', '8'] }];
boomFrames.forEach((f, k) => {
  const rows = [];
  for (let j = 0; j < 8; j++) {
    let r = '';
    for (let i = 0; i < 8; i++) {
      const d = Math.hypot(i - 3.5, j - 3.5);
      if (d <= f.r - 1) r += f.c[1];
      else if (d <= f.r) r += (i + j) % 2 ? f.c[0] : f.c[1];
      else if (d <= f.r + 0.7 && (i + j) % 2) r += f.c[0];
      else r += '.';
    }
    rows.push(r);
  }
  put(80 + k, rows);
});

// --- HUD: 96 shell, 97 spent shell, 98 life pip, 99 arrow ---
put(96, ['........', '...7....', '..aaa...', '..a9a...', '..999...', '..999...', '..494...', '........']);
put(97, ['........', '...5....', '..555...', '..505...', '..000...', '..000...', '..050...', '........']);
put(98, ['........', '...3....', '.3bbb3..', '.33333..', '.3b7b3..', '.33333..', '........', '........']);
put(99, ['........', '..7.....', '..77....', '..777...', '..77....', '..7.....', '........', '........']);

// --- logo "TANK / BATTLE": 5x7 font scaled 2x, drawn at sheet (0,80) size 70x30 ---
const FONT = {
  T: ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  A: ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  N: ['#...#', '##..#', '##..#', '#.#.#', '#..##', '#..##', '#...#'],
  K: ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
  B: ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
  L: ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
  E: ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
};
function logoWord(word, ox, oy) {
  const w = word.length * 12 - 2;
  const startX = ox + Math.floor((70 - w) / 2);
  [...word].forEach((ch, k) => {
    const g = FONT[ch];
    for (let j = 0; j < 7; j++) for (let i = 0; i < 5; i++) if (g[j][i] === '#')
      for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) {
        const yy = j * 2 + dy;
        // green top, dark-green bottom with a dithered seam
        let c = yy < 8 ? 11 : yy < 10 ? ((i * 2 + dx + yy) % 2 ? 11 : 3) : 3;
        sheet[oy + yy][startX + k * 12 + i * 2 + dx] = c;
      }
  });
}
logoWord('TANK', 0, 80);
logoWord('BATTLE', 0, 96);
// outline (0) and drop shadow (5) around the logo pixels
{
  const box = (x, y) => x >= 0 && x < 70 && y >= 80 && y < 110 ? sheet[y][x] : 15;
  const src = sheet.map(r => r.slice());
  for (let y = 80; y < 110; y++) for (let x = 0; x < 70; x++) {
    if (src[y][x] !== 15) continue;
    let near = false, shadow = false;
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
      const v = src[y + dy] && src[y + dy][x + dx];
      if (v === 11 || v === 3) near = true;
    }
    if (near) sheet[y][x] = 0;
    else if (src[y - 1] && src[y - 1][x - 1] === 0 || (src[y - 1] && (src[y - 1][x - 1] === 11 || src[y - 1][x - 1] === 3))) sheet[y][x] = 5;
  }
}

// ---------------------------------------------------------------- flags
// 0 blocks tank, 1 blocks bullet, 2 ricochet, 3 brick, 4 ground layer, 5 bush layer
const gff = new Array(256).fill(0);
gff[16] = gff[17] = 0x01 | 0x02 | 0x08 | 0x10;
gff[18] = 0x01 | 0x02 | 0x04 | 0x10;
gff[20] = 0x01 | 0x10;
gff[22] = 0x20;
gff[24] = 0x10;

// ---------------------------------------------------------------- levels
// 14 cols x 13 rows. '.' empty  '#' brick  'S' steel  '~' water  '*' bush  '^' spawner
// Player spawns at (6,12). Boss levels need (6..7, 0..1) clear.
const T = { '.': 0, '#': 16, S: 18, '~': 20, '*': 22, '^': 24 };
const LEVELS = [
// 1 open field
`^.....^......^
..............
..............
..............
....#....#....
..............
..............
..............
....#....#....
..............
..............
..............
..............`,
// 2 a few posts
`^............^
..............
...#......#...
..............
..............
......##......
......##......
..............
..............
...#......#...
..............
..............
..............`,
// 3 two low walls
`^.....^......^
..............
..............
..............
..##......##..
..............
..............
..............
.....####.....
..............
..............
..............
..............`,
// 4 brick maze intro
`^............^
..............
.###..##..###.
..............
..#.######.#..
..#........#..
..#.######.#..
..............
.##...##...##.
..............
..............
..............
..............`,
// 5 brick corridors (runners appear)
`^.....^......^
..............
.#.##.##.##.#.
.#..........#.
.#.##.##.##.#.
..............
##.##....##.##
..............
.#.##.##.##.#.
.#..........#.
.#.##.##.##.#.
..............
..............`,
// 6 brick fortress
`^............^
..............
..############
..#...........
..#.#########.
..#.#.......#.
..#.#..###..#.
..#.#..###..#.
..#.#.......#.
..#.#########.
..#...........
..############
..............`,
// 7 steel intro: bank shot corridor
`^.....^......^
..............
..S........S..
..............
..............
S.....SS.....S
..............
..............
..S........S..
..............
..............
..............
..............`,
// 8 steel pillars + brick (gunners)
`^............^
..............
.S..#....#..S.
....#....#....
..............
..#S......S#..
..............
..............
.S..#....#..S.
....#....#....
..............
..............
..............`,
// 9 ricochet alley
`^.....^......^
..............
SSSSS....SSSSS
..............
...........#..
..#...SS......
......SS...#..
..#...........
..............
SSSSS....SSSSS
..............
..............
..............`,
// 10 BOSS arena
`^............^
..............
..............
..S........S..
..............
....#....#....
..............
....#....#....
..............
..S........S..
..............
..............
..............`,
// 11 water lanes
`^.....^......^
..............
..............
~~~~~....~~~~~
..............
..............
..#..~~~~..#..
..............
..............
~~~~~....~~~~~
..............
..............
..............`,
// 12 bush ambush
`^............^
..............
**...........*
**.#.......#.*
.....*****....
.....*****....
..............
..**.......**.
..**.......**.
....#####.....
..............
..............
..............`,
// 13 armor march
`^.....^......^
..............
.##........##.
.##..S..S..##.
..............
....######....
..............
.##..S..S..##.
.##........##.
..............
..............
..............
..............`,
// 14 river crossing
`^............^
..............
..............
~~~~..~~..~~~~
..............
.*..S....S..*.
.*..........*.
..............
~~..~~~~~~..~~
..............
..............
..............
..............`,
// 15 gunner gallery
`^.....^......^
..............
S.S.S.S..S.S.S
..............
..#..#..#..#..
..............
..#..#..#..#..
..............
..#..#..#..#..
..............
S.S.S.S..S.S.S
..............
..............`,
// 16 the vault
`^............^
..............
.SSSS....SSSS.
.S..........S.
.S.######.....
.S.#....#..S..
...#.**.#..S..
...#....#..S..
.S.######.....
.S..........S.
.SSSS....SSSS.
..............
..............`,
// 17 crossfire
`^.....^......^
..............
..#..~~~~..#..
..#........#..
S.#.S....S.#.S
..............
....*....*....
..............
S.#.S....S.#.S
..#........#..
..#..~~~~..#..
..............
..............`,
// 18 jungle
`^............^
..*..........*
*****..#..****
..*..........*
.....S....S...
..****....***.
..*..........*
.....S....S...
..*..........*
*****..#..****
..*..........*
..............
..............`,
// 19 gauntlet
`^.....^......^
..............
S#S#S....S#S#S
..............
..~~~~..~~~~..
..............
#....SS.S....#
..............
..~~~~..~~~~..
..............
S#S#S....S#S#S
..............
..............`,
// 20 final BOSS
`^............^
..............
..............
.SS..#..#..SS.
..............
..#..S..S..#..
..............
..#..S..S..#..
..............
.SS..#..#..SS.
..*........*..
..............
..............`,
];
if (LEVELS.length !== 20) throw new Error('need 20 levels');

// map tiles 128 x 64 (rows 32..63 live in gfx lines 64..127)
const mapT = [];
for (let y = 0; y < 64; y++) mapT.push(new Array(128).fill(0));
LEVELS.forEach((src, i) => {
  const rows = src.split('\n');
  if (rows.length !== 13) throw new Error('level ' + (i + 1) + ' rows ' + rows.length);
  const bx = (i % 9) * 14, by = Math.floor(i / 9) * 13;
  rows.forEach((r, y) => {
    if (r.length !== 14) throw new Error('level ' + (i + 1) + ' row ' + y + ' width');
    for (let x = 0; x < 14; x++) {
      if (T[r[x]] === undefined) throw new Error('level ' + (i + 1) + ' bad char ' + r[x]);
      mapT[by + y][bx + x] = T[r[x]];
    }
  });
  if (rows[12][6] !== '.') throw new Error('level ' + (i + 1) + ' player spawn blocked');
});
// rows 32+ into the shared gfx region (nibble-swapped)
for (let y = 32; y < 39; y++) for (let x = 0; x < 128; x++) {
  const v = mapT[y][x];
  const line = 64 + (y - 32) * 2 + (x >= 64 ? 1 : 0);
  const px = (x % 64) * 2;
  sheet[line][px] = v & 15; sheet[line][px + 1] = v >> 4;
}

// ---------------------------------------------------------------- sfx
const W = { tri: 0, tsaw: 1, saw: 2, sqr: 3, pul: 4, org: 5, noi: 6, pha: 7 };
function line(speed, notes, ls, le) {
  let s = '01' + h2(speed) + h2(ls || 0) + h2(le || 0);
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    s += n ? h2(n[0]) + h1(n[1]) + h1(n[2]) + h1(n[3] || 0) : '00000';
  }
  if (s.length !== 168) throw new Error('sfx line width ' + s.length);
  return s;
}
const sfx = [];
// 0 rotate: soft click
sfx[0] = line(2, [[0x18, W.tri, 3, 0], [0x12, W.tri, 2, 5]]);
// 1 step: short tick
sfx[1] = line(2, [[0x10, W.tri, 2, 5]]);
// 2 fire
sfx[2] = line(3, [[0x30, W.noi, 6, 0], [0x24, W.noi, 5, 3], [0x18, W.sqr, 4, 3], [0x10, W.noi, 3, 5]]);
// 3 empty magazine: dry clunk
sfx[3] = line(4, [[0x0c, W.sqr, 4, 0], [0x08, W.sqr, 3, 5]]);
// 4 shell reloaded: blip
sfx[4] = line(3, [[0x2a, W.pul, 3, 0], [0x31, W.pul, 3, 5]]);
// 5 brick hit
sfx[5] = line(3, [[0x1c, W.noi, 5, 0], [0x14, W.noi, 4, 3], [0x0c, W.noi, 3, 5]]);
// 6 steel ping: rising
sfx[6] = line(3, [[0x30, W.pha, 5, 1], [0x36, W.pha, 5, 1], [0x3c, W.pha, 4, 5]]);
// 7 ricochet kill chime
sfx[7] = line(4, [[0x30, W.org, 5, 0], [0x34, W.org, 5, 0], [0x37, W.org, 5, 0], [0x3c, W.org, 6, 5], [0x3c, W.org, 4, 5]]);
// 8 explosion
sfx[8] = line(4, [[0x28, W.noi, 7, 0], [0x1e, W.noi, 7, 3], [0x14, W.noi, 6, 3], [0x0c, W.noi, 5, 3], [0x06, W.noi, 4, 5], [0x03, W.noi, 2, 5]]);
// 9 armor hit: metallic
sfx[9] = line(3, [[0x22, W.sqr, 5, 0], [0x1a, W.noi, 4, 3], [0x10, W.sqr, 3, 5]]);
// 10 spawn warning blip
sfx[10] = line(5, [[0x24, W.pul, 4, 0], null, [0x24, W.pul, 4, 5]]);
// 11 player hit
sfx[11] = line(5, [[0x30, W.noi, 7, 0], [0x24, W.noi, 7, 3], [0x1c, W.saw, 6, 3], [0x12, W.noi, 6, 3], [0x08, W.noi, 5, 5], [0x04, W.noi, 3, 5]]);
// 12 life lost: shatter
sfx[12] = line(4, [[0x2c, W.sqr, 4, 0], [0x26, W.sqr, 4, 0], [0x1e, W.sqr, 4, 0], [0x14, W.sqr, 3, 5]]);
// 13 quota tick
sfx[13] = line(2, [[0x34, W.pul, 3, 0], [0x3a, W.pul, 2, 5]]);
// 14 level complete
sfx[14] = line(8, [[0x18, W.org, 5, 0], [0x1c, W.org, 5, 0], [0x1f, W.org, 5, 0], [0x24, W.org, 6, 0], [0x24, W.org, 5, 5], [0x24, W.org, 3, 5]]);
// 15 boss appears: low rumble rising
sfx[15] = line(8, [[0x08, W.tsaw, 5, 2], [0x0a, W.tsaw, 5, 2], [0x0c, W.tsaw, 6, 2], [0x0f, W.tsaw, 6, 2], [0x0f, W.tsaw, 5, 5]]);
// 16 boss defeated: long explosion
sfx[16] = line(8, [[0x30, W.noi, 7, 0], [0x28, W.noi, 7, 0], [0x20, W.noi, 7, 3], [0x18, W.noi, 6, 3], [0x10, W.noi, 6, 3], [0x0a, W.noi, 5, 5], [0x05, W.noi, 4, 5], [0x02, W.noi, 2, 5]]);
// 17 menu move
sfx[17] = line(2, [[0x2c, W.pul, 3, 0], [0x30, W.pul, 3, 5]]);
// 18 start pressed
sfx[18] = line(4, [[0x24, W.org, 5, 0], [0x2b, W.org, 5, 0], [0x30, W.org, 6, 5]]);
// 19 progress cleared
sfx[19] = line(5, [[0x30, W.sqr, 5, 0], [0x2a, W.sqr, 5, 0], [0x24, W.sqr, 5, 0], [0x1e, W.sqr, 4, 5]]);
// 20 level complete sting: 4 ascending organ chords
sfx[20] = line(9, [
  [0x18, W.org, 5, 0], [0x1c, W.org, 5, 0], [0x1f, W.org, 5, 0], [0x24, W.org, 5, 0],
  [0x1d, W.org, 5, 0], [0x21, W.org, 5, 0], [0x24, W.org, 5, 0], [0x29, W.org, 5, 0],
  [0x1f, W.org, 5, 0], [0x23, W.org, 5, 0], [0x26, W.org, 5, 0], [0x2b, W.org, 5, 0],
  [0x24, W.org, 6, 0], [0x28, W.org, 6, 0], [0x2b, W.org, 6, 0], [0x30, W.org, 6, 0],
  [0x30, W.org, 5, 5], [0x30, W.org, 3, 5]]);
// 21 game over: 3 descending soft triangle notes
sfx[21] = line(14, [[0x1c, W.tri, 5, 0], [0x1c, W.tri, 4, 5], [0x17, W.tri, 5, 0], [0x17, W.tri, 4, 5], [0x10, W.tri, 5, 0], [0x10, W.tri, 4, 5], [0x10, W.tri, 2, 5]]);

// ---------------------------------------------------------------- music
// no noise anywhere in here. channels: 1 arp/pad, 2 melody, 3 bass; 0 stays free for sfx.
const N = {}; // note names -> pitch (c0 = 0)
['c', 'cs', 'd', 'ds', 'e', 'f', 'fs', 'g', 'gs', 'a', 'as', 'b'].forEach((n, i) => {
  for (let o = 0; o < 6; o++) N[n + o] = i + o * 12;
});
const S = 0; // sfx cursor for music
let cur = 22;
function addSfx(l) { sfx[cur] = l; return cur++; }

// bass: root/fifth/octave walking line, one 32-step (2 bar) pattern for two roots
function bassPat(speed, roots, wave, vol) {
  const out = [];
  for (const r of roots) {
    const seq = [r, null, r + 12, null, r + 7, null, r + 12, null, r, null, r + 12, null, r + 7, null, r + 5, null];
    for (const p of seq) out.push(p == null ? null : [p, wave, vol, 0]);
  }
  return line(speed, out);
}
// arp: chord tones cycling, quiet
function arpPat(speed, chords, wave, vol) {
  const out = [];
  for (const c of chords) {
    const tones = [c[0], c[1], c[2], c[0] + 12, c[2], c[1], c[0], c[1]];
    for (let i = 0; i < 16; i++) out.push([tones[i % 8], wave, vol, i % 4 === 3 ? 5 : 0]);
  }
  return line(speed, out);
}
// pad: two held chords (organ, fade in)
function padPat(speed, chords, vol) {
  const out = [];
  for (const c of chords) {
    for (let i = 0; i < 16; i++) out.push(i % 8 === 0 ? [c[0] + 12, W.org, vol, 4] : [c[0] + 12, W.org, vol, 0]);
  }
  return line(speed, out);
}
function melPat(speed, slots, wave, vol) {
  return line(speed, slots.map(p => (p ? [p, wave, vol, 5] : null)));
}
const C = [N.c2, N.e2, N.g2], F = [N.f2, N.a2, N.c3], G = [N.g2, N.b2, N.d3], Am = [N.a2, N.c3, N.e3],
      Dm = [N.d2, N.f2, N.a2], Em = [N.e2, N.g2, N.b2];

// --- track 0: intro. ~100bpm sixteenths -> speed 18. C major, warm pad + simple pulse melody.
const IS = 18;
const ib = [addSfx(bassPat(IS, [N.c1, N.g1], W.tri, 4)), addSfx(bassPat(IS, [N.a1, N.f1], W.tri, 4))];
const ip = [addSfx(padPat(IS, [C, G], 3)), addSfx(padPat(IS, [Am, F], 3))];
const m = N;
const im = [
  addSfx(melPat(IS, [m.e3, 0, 0, m.g3, 0, 0, m.c4, 0, 0, 0, m.b3, 0, m.g3, 0, 0, 0,
                     m.d3, 0, 0, m.g3, 0, 0, m.b3, 0, 0, 0, m.a3, 0, m.g3, 0, 0, 0], W.pul, 4)),
  addSfx(melPat(IS, [m.e3, 0, 0, m.a3, 0, 0, m.c4, 0, 0, 0, m.e4, 0, m.c4, 0, 0, 0,
                     m.c3, 0, 0, m.f3, 0, 0, m.a3, 0, 0, 0, m.g3, 0, m.f3, 0, m.e3, 0], W.pul, 4)),
  addSfx(melPat(IS, [m.g3, 0, 0, m.e3, 0, 0, m.c3, 0, 0, 0, m.e3, 0, m.g3, 0, 0, 0,
                     m.b3, 0, 0, m.g3, 0, 0, m.d3, 0, 0, 0, m.g3, 0, m.b3, 0, 0, 0], W.pul, 4)),
  addSfx(melPat(IS, [m.c4, 0, 0, m.a3, 0, 0, m.e3, 0, 0, 0, m.a3, 0, m.c4, 0, 0, 0,
                     m.f3, 0, 0, m.a3, 0, 0, m.c4, 0, 0, 0, m.b3, 0, 0, 0, m.c4, 0], W.pul, 4)),
];

// --- track 1: game. ~120bpm -> speed 15. A-B-A-C, walking triangle bass + pulse arp.
const GS = 15;
const gb = {
  a: addSfx(bassPat(GS, [N.c1, N.g1], W.tri, 5)),
  b: addSfx(bassPat(GS, [N.a1, N.f1], W.tri, 5)),
  c: addSfx(bassPat(GS, [N.f1, N.g1], W.tri, 5)),
  d: addSfx(bassPat(GS, [N.d1, N.g1], W.tri, 5)),
};
const ga = {
  a: addSfx(arpPat(GS, [C, G], W.pul, 2)),
  b: addSfx(arpPat(GS, [Am, F], W.pul, 2)),
  c: addSfx(arpPat(GS, [F, G], W.pul, 2)),
  d: addSfx(arpPat(GS, [Dm, G], W.pul, 2)),
};
const gm = [
  addSfx(melPat(GS, [m.e3, 0, m.g3, 0, m.c4, 0, 0, m.g3, m.e3, 0, m.g3, 0, m.a3, 0, m.g3, 0,
                     m.d3, 0, m.g3, 0, m.b3, 0, 0, m.g3, m.d4, 0, m.b3, 0, m.g3, 0, m.d3, 0], W.tsaw, 4)),
  addSfx(melPat(GS, [m.e3, 0, m.g3, 0, m.c4, 0, 0, m.d4, m.e4, 0, m.d4, 0, m.c4, 0, m.g3, 0,
                     m.b3, 0, m.g3, 0, m.d3, 0, 0, m.g3, m.b3, 0, m.d4, 0, m.g4, 0, 0, 0], W.tsaw, 4)),
  addSfx(melPat(GS, [m.a3, 0, m.c4, 0, m.e4, 0, 0, m.c4, m.a3, 0, m.c4, 0, m.b3, 0, m.a3, 0,
                     m.f3, 0, m.a3, 0, m.c4, 0, 0, m.a3, m.f3, 0, m.a3, 0, m.g3, 0, m.f3, 0], W.tsaw, 4)),
  addSfx(melPat(GS, [m.a3, 0, m.e4, 0, m.c4, 0, 0, m.a3, m.e4, 0, m.c4, 0, m.a3, 0, m.e3, 0,
                     m.f3, 0, m.c4, 0, m.a3, 0, 0, m.f3, m.c4, 0, m.a3, 0, m.f3, 0, m.c3, 0], W.tsaw, 4)),
  addSfx(melPat(GS, [m.f3, 0, m.a3, 0, m.c4, 0, 0, m.a3, m.f4, 0, m.e4, 0, m.c4, 0, m.a3, 0,
                     m.g3, 0, m.b3, 0, m.d4, 0, 0, m.b3, m.g4, 0, m.f4, 0, m.d4, 0, m.b3, 0], W.tsaw, 4)),
  addSfx(melPat(GS, [m.d3, 0, m.f3, 0, m.a3, 0, 0, m.f3, m.d4, 0, m.c4, 0, m.a3, 0, m.f3, 0,
                     m.g3, 0, m.b3, 0, m.d4, 0, 0, m.g4, m.g4, 0, 0, 0, m.d4, 0, m.b3, 0], W.tsaw, 4)),
];

// --- track 2: boss. faster (speed 12), down a third (A minor), phaser lead.
const BS = 12;
const bb = [addSfx(bassPat(BS, [N.a1, N.e1], W.tri, 5)), addSfx(bassPat(BS, [N.f1, N.e1], W.tri, 5))];
const ba = [addSfx(arpPat(BS, [Am, Em], W.pul, 2)), addSfx(arpPat(BS, [F, Em], W.pul, 2))];
const bm = [
  addSfx(melPat(BS, [m.a3, 0, m.c4, 0, m.e4, 0, 0, m.c4, m.a3, 0, m.c4, 0, m.d4, 0, m.c4, 0,
                     m.e3, 0, m.gs3, 0, m.b3, 0, 0, m.gs3, m.e4, 0, m.b3, 0, m.gs3, 0, m.e3, 0], W.pha, 4)),
  addSfx(melPat(BS, [m.a3, 0, m.e4, 0, m.a4, 0, 0, m.e4, m.c4, 0, m.e4, 0, m.a3, 0, 0, 0,
                     m.e3, 0, m.b3, 0, m.e4, 0, 0, m.b3, m.gs3, 0, m.b3, 0, m.e3, 0, 0, 0], W.pha, 4)),
  addSfx(melPat(BS, [m.f3, 0, m.a3, 0, m.c4, 0, 0, m.a3, m.f4, 0, m.e4, 0, m.c4, 0, m.a3, 0,
                     m.e3, 0, m.gs3, 0, m.b3, 0, 0, m.gs3, m.e4, 0, m.d4, 0, m.b3, 0, m.gs3, 0], W.pha, 4)),
  addSfx(melPat(BS, [m.f4, 0, m.e4, 0, m.c4, 0, 0, m.a3, m.f4, 0, m.e4, 0, m.c4, 0, m.a3, 0,
                     m.b3, 0, m.gs3, 0, m.e3, 0, 0, m.gs3, m.b3, 0, m.e4, 0, m.gs4, 0, 0, 0], W.pha, 4)),
];
if (cur > 64) throw new Error('too many sfx: ' + cur);
for (let i = 0; i < 64; i++) if (!sfx[i]) sfx[i] = line(1, []);

// no-noise check on every music slot
for (let i = 22; i < cur; i++) for (let k = 0; k < 32; k++) {
  const wave = parseInt(sfx[i][8 + k * 5 + 2], 16), vol = parseInt(sfx[i][8 + k * 5 + 3], 16);
  if (vol > 0 && wave === 6) throw new Error('noise in music sfx ' + i);
}

const pat = (flag, a, b, c) => flag + ' 41' + h2(a) + h2(b) + h2(c);
const music = [
  // 0-3 intro
  pat('01', ip[0], im[0], ib[0]), pat('00', ip[1], im[1], ib[1]),
  pat('00', ip[0], im[2], ib[0]), pat('02', ip[1], im[3], ib[1]),
  // 4-11 game: A B A C
  pat('01', ga.a, gm[0], gb.a), pat('00', ga.a, gm[1], gb.a),
  pat('00', ga.b, gm[2], gb.b), pat('00', ga.b, gm[3], gb.b),
  pat('00', ga.a, gm[0], gb.a), pat('00', ga.a, gm[1], gb.a),
  pat('00', ga.c, gm[4], gb.c), pat('02', ga.d, gm[5], gb.d),
  // 12-15 boss
  pat('01', ba[0], bm[0], bb[0]), pat('00', ba[0], bm[1], bb[0]),
  pat('00', ba[1], bm[2], bb[1]), pat('02', ba[1], bm[3], bb[1]),
];

// ---------------------------------------------------------------- write
const gfxLines = sheet.map(r => r.map(v => h1(v)).join(''));
gfxLines.forEach(l => { if (l.length !== 128) throw new Error('gfx width'); });
const gffLines = [gff.slice(0, 128).map(h2).join(''), gff.slice(128).map(h2).join('')];
gffLines.forEach(l => { if (l.length !== 256) throw new Error('gff width'); });
const mapLines = mapT.slice(0, 32).map(r => r.map(h2).join(''));
mapLines.forEach(l => { if (l.length !== 256) throw new Error('map width'); });

const cart = fs.readFileSync(CART, 'utf8');
const cut = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
const head = cut < 0 ? cart : cart.slice(0, cut);
const labelM = cart.match(/^__label__\n([\s\S]*?)(?=^__(gff|map|sfx|music)__$)/m);
const label = labelM ? '__label__\n' + labelM[1] : '';
const out = head + '__gfx__\n' + gfxLines.join('\n') + '\n' + label +
  '__gff__\n' + gffLines.join('\n') + '\n' +
  '__map__\n' + mapLines.join('\n') + '\n' +
  '__sfx__\n' + sfx.join('\n') + '\n' +
  '__music__\n' + music.join('\n') + '\n\n';
fs.writeFileSync(CART, out);
console.log('wrote', CART, 'sfx used', cur, 'music patterns', music.length);
