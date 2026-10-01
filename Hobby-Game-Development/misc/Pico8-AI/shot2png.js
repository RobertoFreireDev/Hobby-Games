// shot2png.js — turn a shot.p8l screen dump (128 hex chars per row,
// N screens of 128 rows) into a scaled PNG contact sheet.
const fs = require('fs'), zlib = require('zlib');
const PAL = [[0,0,0],[29,43,83],[126,37,83],[0,135,81],[171,82,54],[95,87,79],[194,195,199],[255,241,232],
  [255,0,77],[255,163,0],[255,236,39],[0,228,54],[41,173,255],[131,118,156],[255,119,168],[255,204,170]];
const lines = fs.readFileSync(process.argv[2], 'utf8').split(/\r?\n/).filter(l => /^[0-9a-f]{128}$/.test(l));
const n = lines.length / 128, S = 3, cols = Math.min(n, 2);
const rows = Math.ceil(n / cols), pad = 6;
const W = cols * (128 * S + pad) + pad, H = rows * (128 * S + pad) + pad;
const img = Buffer.alloc(W * H * 3, 40);
for (let s = 0; s < n; s++) {
  const ox = pad + (s % cols) * (128 * S + pad), oy = pad + Math.floor(s / cols) * (128 * S + pad);
  for (let y = 0; y < 128; y++) for (let x = 0; x < 128; x++) {
    const c = PAL[parseInt(lines[s * 128 + y][x], 16)];
    for (let dy = 0; dy < S; dy++) for (let dx = 0; dx < S; dx++) {
      const o = ((oy + y * S + dy) * W + ox + x * S + dx) * 3;
      img[o] = c[0]; img[o + 1] = c[1]; img[o + 2] = c[2];
    }
  }
}
const raw = Buffer.alloc(H * (W * 3 + 1));
for (let y = 0; y < H; y++) img.copy(raw, y * (W * 3 + 1) + 1, y * W * 3, (y + 1) * W * 3);
const crcT = [...Array(256)].map((_, i) => { let c = i; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc = b => { let c = 0xffffffff; for (const v of b) c = crcT[(c ^ v) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const chunk = (t, d) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([l, td, c]); };
const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 2;
fs.writeFileSync(process.argv[3], Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
console.log('wrote ' + process.argv[3] + ' (' + n + ' screens, ' + W + 'x' + H + ')');
