// sheet-preview.js -- render the generated sprite sheet to a PNG so the art can
// actually be looked at.
//
//   node sheet-preview.js [out.png] [scale]
//
// Three panels, top to bottom:
//   1. the raw 128x48 sheet, placeholders and all
//   2. the eight villagers with their own hue ramps substituted, which is the
//      only way to see what the board really looks like
//   3. a mock of the Night 7 board from the design document, drawn the way
//      dwboard() draws it -- ground tile, landmark over it, figures on top.
//      Tiles that read alone can still fail side by side; this is the check
//      that matters.

'use strict';
const fs = require('fs'), zlib = require('zlib');
const { buildGfx, HUE, HHI, HLO } = require('./gen-sprites.js');

const PAL = ['000000','1D2B53','7E2553','008751','AB5236','5F574F','C2C3C7','FFF1E8',
             'FF004D','FFA300','FFEC27','00E436','29ADFF','83769C','FF77A8','FFCCAA'];

function crc32(buf, T = crc32.T) {
  if (!T) { T = crc32.T = []; for (let n = 0; n < 256; n++) { let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; T[n] = c; } }
  let c = 0xFFFFFFFF;
  for (const b of buf) c = T[(c ^ b) & 0xFF] ^ (c >>> 8);
  return (c ^ 0xFFFFFFFF) >>> 0;
}

function png(grid, file, scale) {
  const H = grid.length, W = grid[0].length, PW = W * scale, PH = H * scale;
  const raw = Buffer.alloc((PW * 3 + 1) * PH);
  let p = 0;
  for (let y = 0; y < PH; y++) {
    raw[p++] = 0;
    for (let x = 0; x < PW; x++) {
      const rgb = PAL[grid[(y / scale) | 0][(x / scale) | 0]];
      raw[p++] = parseInt(rgb.slice(0, 2), 16);
      raw[p++] = parseInt(rgb.slice(2, 4), 16);
      raw[p++] = parseInt(rgb.slice(4, 6), 16);
    }
  }
  const chunk = (t, d) => {
    const l = Buffer.alloc(4); l.writeUInt32BE(d.length);
    const b = Buffer.concat([Buffer.from(t, 'ascii'), d]);
    const c = Buffer.alloc(4); c.writeUInt32BE(crc32(b));
    return Buffer.concat([l, b, c]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(PW, 0); ihdr.writeUInt32BE(PH, 4); ihdr[8] = 8; ihdr[9] = 2;
  fs.writeFileSync(file, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

const sheet = buildGfx().split('\n').map(l => [...l].map(h => parseInt(h, 16)));
const blank = n => Array.from({ length: n }, () => new Array(128).fill(0));

// panel 2 -- the villagers as the cart draws them
const strip = Array.from({ length: 18 }, () => new Array(128).fill(1));
for (let v = 0; v < 8; v++) {
  const map = { 11: HHI[v], 12: HUE[v], 13: HLO[v], 3: 0 };
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
    const c = sheet[y][v * 16 + x];
    if (c === 0) continue;                            // transparent on figures
    strip[y + 1][v * 16 + x] = map[c] !== undefined ? map[c] : c;
  }
}

// panel 3 -- Night 7, design section 6. 1-8 landmarks, 9-11 nature, v1-v8
// villagers, 0 empty, -1 the player.
const LM = { 1:[0,1], 2:[1,1], 3:[2,1], 4:[3,1], 5:[4,1], 6:[5,1], 7:[6,1], 8:[7,1],
             9:[0,2], 10:[1,2], 11:[2,2] };
const NIGHT7 = [
  [9, 0, 7, 'v2', 10, 0],
  [0, 'v8', 0, 0, 0, 'v1'],
  ['v7', 6, '@', 0, 1, 4],
  [0, 0, 0, 8, 0, 'v5'],
  [11, 2, 'v3', 0, 'v6', 0],
  [0, 0, 0, 3, 'v4', 5],
];
const board = Array.from({ length: 96 }, () => new Array(128).fill(0));
function blit(tx, ty, dx, dy, remap) {
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
    let c = sheet[ty * 16 + y][tx * 16 + x];
    if (remap) {
      if (c === 0) continue;                          // figures: 0 is transparent
      if (remap[c] !== undefined) c = remap[c];
    }
    board[dy + y][dx + x] = c;
  }
}
for (let r = 0; r < 6; r++) {
  for (let c = 0; c < 6; c++) {
    const cell = NIGHT7[r][c], dx = 16 + c * 16, dy = r * 16;
    blit(3, 2, dx, dy);                               // ground under everything
    if (typeof cell === 'number' && cell > 0) blit(LM[cell][0], LM[cell][1], dx, dy);
  }
}
for (let r = 0; r < 6; r++) {
  for (let c = 0; c < 6; c++) {
    const cell = NIGHT7[r][c], dx = 16 + c * 16, dy = r * 16;
    if (cell === '@') { blit(4, 2, dx, dy - 2, { 3: 0 }); continue; }
    if (typeof cell !== 'string') continue;
    const v = +cell.slice(1) - 1;
    // first three heard already, so the state outline shows in situ
    blit(v, 0, dx, dy, { 11: HHI[v], 12: HUE[v], 13: HLO[v], 3: v < 3 ? 5 : 0 });
  }
}

png([...sheet, ...blank(2), ...strip, ...blank(2), ...board],
    process.argv[2] || 'sheet-preview.png', +(process.argv[3] || 4));
console.log('wrote ' + (process.argv[2] || 'sheet-preview.png'));
