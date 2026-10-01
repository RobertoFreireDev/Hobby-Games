// rotamaze - sprite sheet. 1-bit dungeon: colour 0 (black) and 7 (white)
// only, plus '.' for transparent. everything else on screen is drawn in code.
'use strict';

// '.' transparent  '#' white  'o' opaque black (drawn via pal(1,0))
const UP = [
  '........',
  '...##...',
  '..####..',
  '.##..##.',
  '.######.',
  '.######.',
  '..####..',
  '........',
];

const flipV = g => [...g].reverse();
const flipH = g => g.map(r => [...r].reverse().join(''));
const transpose = g => g[0].split('').map((_, c) => g.map(r => r[c]).join(''));

const DOWN = flipV(UP);
const LEFT = transpose(UP);
const RIGHT = flipH(LEFT);

const BLANK = Array(8).fill('........');

// sprite 0 must stay empty - pico-8 never draws it
// nothing on the board is a sprite any more: the walls, the player token,
// the faced-tile marker and the exit shimmer are all drawn in code, so the
// sheet ships empty. the shapes above are kept because they are the source
// of the token silhouette the cover art draws.
const SPRITES = [BLANK];

const PIX = { '.': 0, '#': 7, o: 1 };

// returns 64 lines of 128 hex digits: gfx lines 0..63 (sprites 0..127)
function gfxArt() {
  const sheet = Array.from({ length: 64 }, () => new Array(128).fill(0));
  SPRITES.forEach((sp, n) => {
    const ox = (n % 16) * 8, oy = ((n / 16) | 0) * 8;
    sp.forEach((rowStr, y) => {
      if (rowStr.length !== 8) throw new Error('sprite ' + n + ' row width');
      [...rowStr].forEach((ch, x) => {
        if (!(ch in PIX)) throw new Error('bad pixel ' + ch);
        sheet[oy + y][ox + x] = PIX[ch];
      });
    });
  });
  return sheet.map(r => r.map(v => v.toString(16)).join(''));
}

function preview() {
  return SPRITES.map((sp, n) => n + ':\n' + sp.map(r => r.replace(/\./g, ' ')).join('\n')).join('\n');
}

module.exports = { gfxArt, SPRITES, preview };
if (require.main === module) console.log(preview());
