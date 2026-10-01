// label-tool.js — turn a headless PICO-8 pixel dump into a cart label.
//
//   node label-tool.js <dump.txt> <cart.p8|-> [preview.png] [scale]
//
// <dump.txt>  stdout of `pico8 -x labelgen.p8`, containing 128 rows of 128
//             hex digits between the markers @@begin and @@end.
// <cart.p8>   cart to splice the __label__ section into ("-" to skip).
// preview.png optional PNG render of the label, for eyeballing the art.
//
// See PICO8-LABEL.md for the whole workflow.
const fs = require('fs'), zlib = require('zlib');

const PAL = ['000000','1D2B53','7E2553','008751','AB5236','5F574F','C2C3C7','FFF1E8',
             'FF004D','FFA300','FFEC27','00E436','29ADFF','83769C','FF77A8','FFCCAA'];

// __label__ must sit after __lua__/__gfx__ and before any of these
const AFTER = ['__gff__', '__map__', '__sfx__', '__music__'];

function readRows(dumpFile) {
  const lines = fs.readFileSync(dumpFile, 'utf8').split(/\r?\n/)
    .map(l => l.replace(/^INFO:\s?/, '').trim());
  const a = lines.indexOf('@@begin'), b = lines.indexOf('@@end');
  if (a < 0 || b < 0) throw new Error(`@@begin/@@end markers missing in ${dumpFile}`);
  const rows = lines.slice(a + 1, b);
  if (rows.length !== 128) throw new Error(`expected 128 rows, got ${rows.length}`);
  rows.forEach((l, i) => {
    if (!/^[0-9a-f]{128}$/.test(l)) throw new Error(`row ${i} is not 128 hex digits: ${l}`);
  });
  return rows;
}

function patch(cart, rows) {
  const src = fs.readFileSync(cart, 'utf8').split(/\r?\n/);
  const kept = [];
  let dropping = false;
  for (const line of src) {                       // strip any existing __label__
    if (/^__\w+__$/.test(line)) dropping = (line === '__label__');
    if (!dropping) kept.push(line);
  }
  const block = ['__label__', ...rows];
  const out = [];
  let placed = false;
  for (const line of kept) {
    if (!placed && AFTER.includes(line)) { out.push(...block); placed = true; }
    out.push(line);
  }
  if (!placed) {                                  // no trailing section: append
    while (out.length && out[out.length - 1] === '') out.pop();
    out.push(...block);
  }
  fs.writeFileSync(cart, out.join('\n').replace(/\n*$/, '\n'), 'utf8');
}

function crc32(buf, T = crc32.T) {
  if (!T) {
    T = crc32.T = [];
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
      T[n] = c;
    }
  }
  let c = 0xFFFFFFFF;
  for (const b of buf) c = T[(c ^ b) & 0xFF] ^ (c >>> 8);
  return (c ^ 0xFFFFFFFF) >>> 0;
}

function png(rows, file, scale) {
  const W = 128 * scale, raw = Buffer.alloc((W * 3 + 1) * W);
  let p = 0;
  for (let y = 0; y < W; y++) {
    raw[p++] = 0;                                 // filter type: none
    for (let x = 0; x < W; x++) {
      const rgb = PAL[parseInt(rows[(y / scale) | 0][(x / scale) | 0], 16)];
      raw[p++] = parseInt(rgb.slice(0, 2), 16);
      raw[p++] = parseInt(rgb.slice(2, 4), 16);
      raw[p++] = parseInt(rgb.slice(4, 6), 16);
    }
  }
  const chunk = (type, data) => {
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body));
    return Buffer.concat([len, body, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(W, 4);
  ihdr[8] = 8; ihdr[9] = 2;                       // 8-bit RGB
  fs.writeFileSync(file, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw)),
    chunk('IEND', Buffer.alloc(0))]));
}

const [dump, cart, preview, scale] = process.argv.slice(2);
if (!dump) { console.error('usage: node label-tool.js <dump.txt> <cart.p8|-> [preview.png] [scale]'); process.exit(1); }
const rows = readRows(dump);
if (preview) { png(rows, preview, +(scale || 3)); console.log(`preview -> ${preview}`); }
if (cart && cart !== '-') { patch(cart, rows); console.log(`patched -> ${cart}`); }
console.log('ok: 128 rows x 128 hex digits');
