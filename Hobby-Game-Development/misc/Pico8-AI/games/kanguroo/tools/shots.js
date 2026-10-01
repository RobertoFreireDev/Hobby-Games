// parses the harness stdout log into one png per shot, scaled 3x,
// and prints the ok/FAIL lines.
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const log = fs.readFileSync(process.argv[2] || path.join(__dirname, "run.log"), "utf8").split(/\r?\n/);
const PAL = ["000000", "1D2B53", "7E2553", "008751", "AB5236", "5F574F", "C2C3C7",
  "FFF1E8", "FF004D", "FFA300", "FFEC27", "00E436", "29ADFF", "83769C", "FF77A8", "FFCCAA"];

const crcTable = [];
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  crcTable[n] = c >>> 0;
}
const crc = (buf) => {
  let c = 0xffffffff;
  for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const cc = Buffer.alloc(4); cc.writeUInt32BE(crc(td));
  return Buffer.concat([len, td, cc]);
};
function png(rows, file, S) {
  const w = 128 * S, h = 128 * S;
  const raw = Buffer.alloc((w * 3 + 1) * h);
  let o = 0;
  for (let y = 0; y < h; y++) {
    raw[o++] = 0;
    for (let x = 0; x < w; x++) {
      const c = PAL[parseInt(rows[Math.floor(y / S)][Math.floor(x / S)], 16)];
      raw[o++] = parseInt(c.slice(0, 2), 16);
      raw[o++] = parseInt(c.slice(2, 4), 16);
      raw[o++] = parseInt(c.slice(4, 6), 16);
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 2;
  fs.writeFileSync(file, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw)), chunk("IEND", Buffer.alloc(0)),
  ]));
}

let cur = null, rows = [], made = [];
const flush = () => {
  if (cur && rows.length === 128) {
    const f = path.join(__dirname, "shot_" + cur + ".png");
    png(rows, f, 3);
    made.push(path.basename(f));
  } else if (cur) {
    console.log("!! shot " + cur + " had " + rows.length + " rows");
  }
};
for (const line of log) {
  const s = line.replace(/^INFO:\s*/, "");
  if (s.startsWith("shot ")) { flush(); cur = s.split(" ")[1]; rows = []; console.log(s); }
  else if (s.startsWith("px ")) rows.push(s.slice(3));
  else if (/^(ok|FAIL|done)/.test(s)) console.log(s);
}
flush();
console.log("wrote: " + made.join(" "));
