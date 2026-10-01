// png.js — turn `SCR <tag>` hex dumps from a cart run into PNGs to eyeball.
//   pico8.exe -x _test.p8 > dump.txt && node png.js dump.txt outdir
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

const PAL = ['000000', '1D2B53', '7E2553', '008751', 'AB5236', '5F574F', 'C2C3C7', 'FFF1E8',
             'FF004D', 'FFA300', 'FFEC27', '00E436', '29ADFF', '83769C', 'FF77A8', 'FFCCAA']
  .map((h) => [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)]);

let TBL = null;
function crc32(buf) {
  if (!TBL) {
    TBL = new Int32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      TBL[n] = c;
    }
  }
  let c = -1;
  for (const b of buf) c = TBL[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

function png(rows, scale) {
  const h = rows.length, w = rows[0].length;
  const W = w * scale, H = h * scale;
  const raw = Buffer.alloc((W * 3 + 1) * H);
  let o = 0;
  for (let y = 0; y < H; y++) {
    raw[o++] = 0; // filter: none
    const row = rows[(y / scale) | 0];
    for (let x = 0; x < W; x++) {
      const c = PAL[parseInt(row[(x / scale) | 0], 16)] || PAL[0];
      raw[o++] = c[0]; raw[o++] = c[1]; raw[o++] = c[2];
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4);
  ihdr[8] = 8; ihdr[9] = 2; // 8-bit RGB
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

const txt = fs.readFileSync(process.argv[2], 'utf8').split(/\r?\n/);
const outdir = process.argv[3] || '.';
let tag = null, rows = [], made = 0;
const flush = () => {
  if (tag && rows.length === 128) {
    const p = path.join(outdir, tag + '.png');
    fs.writeFileSync(p, png(rows, 4));
    console.log('wrote ' + p);
    made++;
  }
  tag = null; rows = [];
};
for (let line of txt) {
  line = line.replace(/^INFO:\s?/, '').trim();
  const m = line.match(/^SCR (\S+)$/);
  if (m) { flush(); tag = m[1]; continue; }
  if (tag && /^[0-9a-f]{128}$/.test(line)) rows.push(line);
}
flush();
if (!made) throw new Error('no complete 128-line screens found in ' + process.argv[2]);
