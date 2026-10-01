// regenerates the __gfx__ section of game.p8
// sheet layout:
//   row 0, cols 1..7 : board pieces, animation frame 0
//   row 1..3, cols 1..7 : frames 1..3  (sprite = base + 16*frame)
//   row 0, cols 8..12 : hud icons   13 = floor+hole  14 = floor
const fs = require('fs');
const E = '........';
const sh = (g, dy) => {           // vertical shift
  const o = [];
  for (let y = 0; y < 8; y++) { const s = y - dy; o.push(s >= 0 && s < 8 ? g[s] : E); }
  return o;
};
const px = (g, x, y, c) => {      // single pixel override
  const o = g.slice();
  o[y] = o[y].substr(0, x) + c + o[y].substr(x + 1);
  return o;
};
const row = (g, y, s) => { const o = g.slice(); o[y] = s; return o; };

// ---- items: 4-frame hover, plus a travelling highlight ----------------
// a plain grey pebble: the stones cover the board, so they
// stay neutral and let the coloured items and monsters read.
const stone = [
  E,
  '..5555..',
  '.566665.',
  '56666665',
  '56666665',
  '.566655.',
  '..5555..',
  E];
const STONE = [
  sh(px(stone, 2, 2, '7'), 0),
  sh(px(stone, 3, 2, '7'), -1),
  sh(px(stone, 4, 3, '7'), -1),
  sh(px(stone, 2, 3, '7'), 0)];

const potion = [
  '...44...',
  '..5665..',
  '.566665.',
  '.56bb65.',
  '5bbbbbb5',
  '5bbbbbb5',
  '.5bbbb5.',
  '..5555..'];
const POTION = [
  px(px(potion, 2, 4, '7'), 4, 6, '7'),
  px(px(potion, 2, 4, '7'), 4, 5, '7'),
  px(px(potion, 2, 5, '7'), 3, 4, '7'),
  px(potion, 2, 5, '7')];

const sword = [
  E,
  '...7....',
  '..5775..',
  '..5675..',
  '..5675..',
  '.5aaaa5.',
  '...44...',
  '..4994..'];
const SWORD = [
  sh(px(sword, 3, 2, '7'), 0),
  sh(px(sword, 3, 3, '7'), -1),
  sh(px(sword, 3, 4, '7'), -1),
  sh(sword, 0)];

// ---- monsters: breathe, blink, chomp ---------------------------------
const slime = [
  E, E,
  '..5555..',
  '.5cccc5.',
  '5c7cc7c5',
  '5cccccc5',
  '.5dddd5.',
  '..5555..'];
const slimeSquash = [
  E, E, E,
  '.5cccc5.',
  '5c7cc7c5',
  '5cccccc5',
  '5cddddc5',
  '.555555.'];
const M1 = [slime, slimeSquash, slime, row(slime, 4, '5c5cc5c5')];

const ghost = [
  E,
  '..5555..',
  '.5eeee5.',
  '5e7ee7e5',
  '5eeeeee5',
  '5eeeeee5',
  '5eeeeee5',
  '5e5ee5e5'];
const M2 = [
  sh(ghost, 0),
  sh(row(ghost, 7, '5ee55ee5'), -1),
  sh(row(ghost, 3, '5e5ee5e5'), -1),
  sh(row(ghost, 7, '5ee55ee5'), 0)];

const brute = [
  E,
  '.5....5.',
  '.59..95.',
  '.599995.',
  '59799795',
  '59999995',
  '59777795',
  '.555555.'];
const M3 = [
  brute,
  row(row(brute, 6, '59999995'), 5, '59777795'),
  brute,
  row(brute, 4, '59599595')];

const demon = [
  '.8....8.',
  '.88..88.',
  '.588885.',
  '58a88a85',
  '58888885',
  '58777785',
  '.588885.',
  '..5555..'];
const M4 = [
  demon,
  row(row(demon, 3, '58888885'), 5, '58999985'),
  demon,
  row(row(demon, 3, '58788785'), 5, '58777785')];

// ---- hud icons + floor ------------------------------------------------
const heart = [E, '.88.88..', '8878888.', '8888888.', '.88888..', '..888...', '...8....', E];
const swico = [E, '.....67.', '....67..', '...67...', '..464...', '.44.....', '4.......', E];
const potico = [E, '..44....', '..565...', '.566b5..', '.56bb5..', '.5bbb5..', '.55555..', E];
const skull = [E, '..777...', '.77777..', '.71717..', '..777...', '.71717..', E, E];
const broken = [E, '.....67.', '....6...', '...67...', '..464...', '.44.....', '4.......', E];
const hole = [
  'd111111.', '1111111.', '1155511.', '1500051.',
  '1500051.', '15ddd51.', '1111111.', E];
const floor = [
  'd111111.', '1111111.', '1111111.', '1111111.',
  '1111111.', '1111111.', '1111111.', E];

const frames = [STONE, POTION, SWORD, M1, M2, M3, M4];
const icons = { 8: heart, 9: swico, 10: potico, 11: skull, 12: broken, 13: hole, 14: floor };

const sheet = [];
for (let y = 0; y < 32; y++) sheet.push(new Array(16).fill(E));
frames.forEach((fr, k) => {
  fr.forEach((g, f) => {
    for (let y = 0; y < 8; y++) sheet[f * 8 + y][k + 1] = g[y];
  });
});
for (const n in icons) for (let y = 0; y < 8; y++) sheet[y][n] = icons[n][y];

const out = sheet.map(r => r.join('').replace(/\./g, '0'));
out.forEach((l, i) => { if (l.length !== 128) throw 'bad line ' + i + ' len ' + l.length; });

const src = fs.readFileSync('game.p8', 'utf8').split(/\r?\n/);
const a = src.indexOf('__gfx__');
let b = a + 1;
while (b < src.length && !src[b].startsWith('__')) b++;
fs.writeFileSync('game.p8', src.slice(0, a + 1).concat(out, src.slice(b)).join('\n'));
console.log('wrote ' + out.length + ' gfx lines');
