// publish-all.js — batch publish every game in games/<name>/game.p8
//
//   node publish-all.js [--scale N] [--only name,name]
//                       [--no-export] [--no-images] [--no-html]
//
// For each cart it:
//   1. exports the cart image to publish/<name>.p8.png (via pico8.exe -export)
//   2. renders the cart's __label__ section to images/<name>.png
//   3. exports a web build (index.html + index.js) and zips it to html/<name>.zip
//
// <name> is the game's folder name. See README.md / notes.txt for the manual steps.
const fs = require('fs'), path = require('path'), zlib = require('zlib');
const { execFileSync } = require('child_process');

const PICO8 = process.env.PICO8 || 'C:/Program Files (x86)/PICO-8/pico8.exe';
const ROOT = __dirname;
const GAMES = path.join(ROOT, 'games');
const PUBLISH = path.join(ROOT, 'publish');
const IMAGES = path.join(ROOT, 'images');
const HTML = path.join(ROOT, 'html');

const PAL = [[0,0,0],[29,43,83],[126,37,83],[0,135,81],[171,82,54],[95,87,79],[194,195,199],[255,241,232],
  [255,0,77],[255,163,0],[255,236,39],[0,228,54],[41,173,255],[131,118,156],[255,119,168],[255,204,170]];

// ---- args -------------------------------------------------------------
const argv = process.argv.slice(2);
const arg = (flag, def) => { const i = argv.indexOf(flag); return i < 0 ? def : argv[i + 1]; };
const SCALE = Math.max(1, parseInt(arg('--scale', '1'), 10) || 1);
const ONLY = (arg('--only', '') || '').split(',').filter(Boolean);
const DO_EXPORT = !argv.includes('--no-export');
const DO_IMAGES = !argv.includes('--no-images');
const DO_HTML = !argv.includes('--no-html');

// ---- crc32, shared by the PNG and ZIP writers -------------------------
const crcT = [...Array(256)].map((_, i) => {
  let c = i; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0;
});
const crc = b => { let c = 0xffffffff; for (const v of b) c = crcT[(c ^ v) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };

// ---- minimal PNG writer (RGB, no alpha) -------------------------------
const chunk = (t, d) => {
  const l = Buffer.alloc(4); l.writeUInt32BE(d.length);
  const td = Buffer.concat([Buffer.from(t), d]);
  const c = Buffer.alloc(4); c.writeUInt32BE(crc(td));
  return Buffer.concat([l, td, c]);
};
function writePng(file, rows, scale) {
  const W = 128 * scale, H = 128 * scale;
  const raw = Buffer.alloc(H * (W * 3 + 1));
  for (let y = 0; y < H; y++) {
    const src = rows[Math.floor(y / scale)];
    let o = y * (W * 3 + 1) + 1;
    for (let x = 0; x < W; x++) {
      const c = PAL[parseInt(src[Math.floor(x / scale)], 16)];
      raw[o++] = c[0]; raw[o++] = c[1]; raw[o++] = c[2];
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 2;
  fs.writeFileSync(file, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

// ---- minimal ZIP writer (deflate, flat archive) -----------------------
// entries: [{ name, data:Buffer }] — flat, no folder, which is what itch.io wants.
function writeZip(file, entries) {
  const now = new Date();
  const dosTime = ((now.getHours() << 11) | (now.getMinutes() << 5) | (now.getSeconds() >> 1)) & 0xffff;
  const dosDate = (((now.getFullYear() - 1980) << 9) | ((now.getMonth() + 1) << 5) | now.getDate()) & 0xffff;
  const locals = [], centrals = [];
  let offset = 0;
  for (const e of entries) {
    const name = Buffer.from(e.name, 'utf8');
    const comp = zlib.deflateRawSync(e.data, { level: 9 });
    const sum = crc(e.data);

    const lh = Buffer.alloc(30);                       // local file header
    lh.writeUInt32LE(0x04034b50, 0); lh.writeUInt16LE(20, 4); lh.writeUInt16LE(0, 6);
    lh.writeUInt16LE(8, 8); lh.writeUInt16LE(dosTime, 10); lh.writeUInt16LE(dosDate, 12);
    lh.writeUInt32LE(sum, 14); lh.writeUInt32LE(comp.length, 18); lh.writeUInt32LE(e.data.length, 22);
    lh.writeUInt16LE(name.length, 26); lh.writeUInt16LE(0, 28);
    locals.push(lh, name, comp);

    const ch = Buffer.alloc(46);                       // central directory entry
    ch.writeUInt32LE(0x02014b50, 0); ch.writeUInt16LE(20, 4); ch.writeUInt16LE(20, 6);
    ch.writeUInt16LE(0, 8); ch.writeUInt16LE(8, 10); ch.writeUInt16LE(dosTime, 12);
    ch.writeUInt16LE(dosDate, 14); ch.writeUInt32LE(sum, 16);
    ch.writeUInt32LE(comp.length, 20); ch.writeUInt32LE(e.data.length, 24);
    ch.writeUInt16LE(name.length, 28); ch.writeUInt32LE(0, 38); ch.writeUInt32LE(offset, 42);
    centrals.push(ch, name);

    offset += 30 + name.length + comp.length;
  }
  const cd = Buffer.concat(centrals);
  const end = Buffer.alloc(22);                        // end of central directory
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(entries.length, 8); end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(cd.length, 12); end.writeUInt32LE(offset, 16);
  fs.writeFileSync(file, Buffer.concat([...locals, cd, end]));
}

// ---- pull the 128 label rows out of a cart ----------------------------
function labelRows(cart) {
  const lines = fs.readFileSync(cart, 'utf8').split(/\r?\n/);
  const a = lines.indexOf('__label__');
  if (a < 0) return null;
  const rows = [];
  for (let i = a + 1; i < lines.length && rows.length < 128; i++) {
    const l = lines[i].trim();
    if (/^__\w+__$/.test(l)) break;
    if (/^[0-9a-f]{128}$/.test(l)) rows.push(l); else if (l !== '') break;
  }
  if (!rows.length) return null;
  while (rows.length < 128) rows.push('0'.repeat(128)); // PICO-8 trims trailing blank rows
  return rows;
}

// ---- main -------------------------------------------------------------
if (!fs.existsSync(GAMES)) { console.error('no games/ directory'); process.exit(1); }
for (const d of [PUBLISH, IMAGES, HTML]) fs.mkdirSync(d, { recursive: true });
if ((DO_EXPORT || DO_HTML) && !fs.existsSync(PICO8)) {
  console.error(`pico8 not found at ${PICO8} (set PICO8=<path> to override)`);
  process.exit(1);
}

const names = fs.readdirSync(GAMES)
  .filter(n => fs.existsSync(path.join(GAMES, n, 'game.p8')))
  .filter(n => !ONLY.length || ONLY.includes(n))
  .sort();

let ok = 0, warn = 0, fail = 0;
for (const name of names) {
  const dir = path.join(GAMES, name), cart = path.join(dir, 'game.p8');
  const line = [name.padEnd(18)];
  const rows = labelRows(cart);   // also gates step 3: pico8 refuses an html
                                  // export from a cart with no captured label

  if (DO_EXPORT) {
    const tmp = path.join(dir, `${name}.p8.png`);
    try {
      execFileSync(PICO8, ['game.p8', '-export', `${name}.p8.png`], { cwd: dir, stdio: 'pipe' });
      if (!fs.existsSync(tmp)) throw new Error('pico8 produced no file');
      fs.renameSync(tmp, path.join(PUBLISH, `${name}.p8.png`));
      line.push(`publish/${name}.p8.png`);
    } catch (e) {
      line.push(`EXPORT FAILED (${e.message.split('\n')[0]})`); fail++;
    }
  }

  if (DO_IMAGES) {
    if (rows) {
      writePng(path.join(IMAGES, `${name}.png`), rows, SCALE);
      line.push(`images/${name}.png`);
    } else {
      line.push('no __label__ — skipped'); warn++;
    }
  }

  if (DO_HTML && !rows) {
    line.push('no label — html export refused'); warn++;
  } else if (DO_HTML) {
    // PICO-8 names the .js after the .html, so the export has to be called
    // index.html for the zip to be a drop-in itch.io upload.
    const stage = path.join(dir, '_webexport');
    try {
      fs.rmSync(stage, { recursive: true, force: true });
      fs.mkdirSync(stage);
      execFileSync(PICO8, ['game.p8', '-export', '_webexport/index.html'], { cwd: dir, stdio: 'pipe' });
      const files = ['index.html', 'index.js'].map(f => {
        const p = path.join(stage, f);
        if (!fs.existsSync(p)) throw new Error(`pico8 produced no ${f}`);
        return { name: f, data: fs.readFileSync(p) };
      });
      const zip = path.join(HTML, `${name}.zip`);
      writeZip(zip, files);
      line.push(`html/${name}.zip (${(fs.statSync(zip).size / 1024).toFixed(0)}kb)`);
    } catch (e) {
      line.push(`HTML FAILED (${e.message.split('\n')[0]})`); fail++;
    } finally {
      fs.rmSync(stage, { recursive: true, force: true });
    }
  }

  if (!line.slice(1).some(s => /FAILED/.test(s))) ok++;
  console.log(line.join('  '));
}
console.log(`\n${names.length} cart(s): ${ok} ok, ${warn} without label, ${fail} failure(s)`);
process.exit(fail ? 1 : 0);
