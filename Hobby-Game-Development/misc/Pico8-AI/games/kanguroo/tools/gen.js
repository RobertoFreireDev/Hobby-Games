// kanguroo asset generator.
// Builds __gfx__ (12x12 tiles laid out 10-across), __sfx__, __music__ and the
// level table, and splices them into ../game.p8.
// Also writes preview.png (4x sprite sheet) for eyeballing the art.

const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const { levels } = require("./levels.js");

const CART = path.join(__dirname, "..", "game.p8");

// ---------------------------------------------------------------- sprite art
// one char per pixel: hex digit = palette colour, '.' = colour 0 (transparent)
//
// ol(rows,col,bg) traces a 1px outline of `col` around every non-`bg` pixel.
// Only the kangaroo uses it: the player is the one sprite that has to stay
// readable on top of sand, rock, water and a box, so it gets a rim and nothing
// else does. Terrain and boxes carry their own edge colours instead.
//
// An outlined core must stay inside x1..x10 / y1..y10 — a pixel on the border
// row or column would have its rim clipped by the tile edge, so ol() throws
// rather than let a sprite lose one side of its outline.

function ol(rows, col, bg) {
  const h = rows.length, w = rows[0].length;
  rows.forEach((r, y) => {
    if (r.length !== w) throw new Error("ragged art row " + y);
    for (let x = 0; x < w; x++) {
      if (r[x] === bg) continue;
      if (y === 0 || y === h - 1 || x === 0 || x === w - 1) {
        throw new Error("art touches the tile edge at " + x + "," + y + " - no room to outline");
      }
    }
  });
  const out = rows.map((r) => r.split(""));
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (rows[y][x] !== bg) continue;
      let touch = false;
      for (let dy = -1; dy <= 1 && !touch; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const ny = y + dy, nx = x + dx;
          if (ny < 0 || nx < 0 || ny >= h || nx >= w) continue;
          if (rows[ny][nx] !== bg) { touch = true; break; }
        }
      }
      if (touch) out[y][x] = col;
    }
  }
  return out.map((r) => r.join(""));
}

const A = {};

// tile 0 is never blitted (dec() returns 0 for plain sand and the caller skips
// it) — it is here so the sheet's first cell is the ground colour.
A.sand = [
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
];

// distant dune crests, each with its own cast shadow. title screen only —
// orange never appears on the board, where it means box or goal.
A.dune = [
  "ffffffffffff",
  "ffffffffffff",
  "ffff9999ffff",
  "fff444444fff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ff9999ffffff",
  "f444444fffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
];

// desert shrub, lit from above: bright green crown, dark green underside,
// brown stem. the two greens give it form without a traced rim.
A.tuft = [
  "ffffffffffff",
  "ffffffffffff",
  "fffffbbfffff",
  "ffffbbbbffff",
  "fffbbbbbbfff",
  "fffbbbb33fff",
  "ffff3333ffff",
  "fffff44fffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
];

// loose stones, same grey as the boulders so scenery reads as one material
A.pebble = [
  "ffffffffffff",
  "ffffffffffff",
  "ffffff655fff",
  "ffffff552fff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
  "fff655ffffff",
  "fff552ffffff",
  "ffffffffffff",
  "ffffffffffff",
  "ffffffffffff",
];

// grey-brown so the brown kangaroo never blends into a rock. lit from the
// top-left, dark contact shadow along the base.
A.rock = [
  "ffffffffffff",
  "ffff5555ffff",
  "fff665555fff",
  "ff66555555ff",
  "ff66555555ff",
  "ff65555555ff",
  "ff65555552ff",
  "ff65555522ff",
  "fff555522fff",
  "ffff2222ffff",
  "ffffffffffff",
  "ffffffffffff",
];

// water is a field, not an object. its edge is stroked in lua against the
// tiles that are actually dry, so a big lake stays open water.
A.waterA = [
  "1cccccccccc1",
  "cccccccccccc",
  "cc77cccccccc",
  "cccccccccc1c",
  "cccccccccccc",
  "c1cccccc77cc",
  "cccccccccccc",
  "cccc11cccccc",
  "cccccccccccc",
  "cc77cccccccc",
  "ccccccccc11c",
  "1cccccccccc1",
];

A.waterB = [
  "1cccccccccc1",
  "cccccc11cccc",
  "cccccccccccc",
  "cc11cccccccc",
  "ccccccc77ccc",
  "cccccccccccc",
  "c77ccccccccc",
  "cccccccc11cc",
  "cccccccccccc",
  "cccc77cccccc",
  "c11ccccccccc",
  "1cccccccccc1",
];

// goal: a broken ring painted on the sand, thick enough to still read as a
// ring where a box overlaps it
A.goal = [
  "ffffffffffff",
  "ffff9999ffff",
  "fff99ff99fff",
  "ff99ffff99ff",
  "ff9ffffff9ff",
  "ffffffffffff",
  "ffffffffffff",
  "ff9ffffff9ff",
  "ff99ffff99ff",
  "fff99ff99fff",
  "ffff9999ffff",
  "ffffffffffff",
];

// crate: orange frame and plank seams, dark lip along the bottom
A.box = [
  "............",
  "..99999999..",
  ".9444994449.",
  ".9444994449.",
  ".9999999999.",
  ".9444994449.",
  ".9444994449.",
  ".9999999999.",
  ".9444994449.",
  ".9444994449.",
  "..22222222..",
  "............",
];

A.boxgoal = [
  "............",
  "..aaaaaaaa..",
  ".a999aa999a.",
  ".a999aa999a.",
  ".aaaaaaaaaa.",
  ".a999aa999a.",
  ".a999aa999a.",
  ".aaaaaaaaaa.",
  ".a999aa999a.",
  ".a999aa999a.",
  "..44444444..",
  "............",
];

// kangaroo, side view facing right. the eye is a solid dark pixel: as colour 0
// it was transparent and picked up whatever tile was behind the head.
A.side = ol([
  "............",
  ".......4..4.",
  ".......4444.",
  ".......424f.",
  "......44444.",
  ".....4444ff.",
  "....44444ff.",
  "...444444f..",
  ".4444444....",
  ".44..44444..",
  "......ffff..",
  "............",
], "2", ".");

A.sidej = ol([
  "............",
  ".......4..4.",
  ".......4444.",
  ".......424f.",
  "......44444.",
  ".....4444ff.",
  "...44444ff..",
  "..4444444...",
  ".44444444...",
  ".44..4444...",
  ".....ffff...",
  "............",
], "2", ".");

// kangaroo, facing the camera (moving down)
A.front = ol([
  "............",
  "..4......4..",
  "..44....44..",
  "...444444...",
  "...424424...",
  "...444444...",
  "..44ffff44..",
  "..44ffff44..",
  "..444ff444..",
  "..ff4..4ff..",
  "..ff....ff..",
  "............",
], "2", ".");

A.frontj = ol([
  "............",
  "............",
  "..4......4..",
  "..44....44..",
  "...444444...",
  "...424424...",
  "...444444...",
  "..44ffff44..",
  "..444ff444..",
  ".4444444444.",
  ".ff44..44ff.",
  "............",
], "2", ".");

// kangaroo, seen from behind (moving up). no eyes or muzzle from this angle —
// the tail below the feet is what tells it apart from the front view.
A.back = ol([
  "............",
  "..4......4..",
  "..44....44..",
  "...444444...",
  "...444444...",
  "..44444444..",
  "..44444444..",
  "..44444444..",
  "...444444...",
  "..ff4444ff..",
  "....4444....",
  "............",
], "2", ".");

A.backj = ol([
  "............",
  "............",
  "..4......4..",
  "..44....44..",
  "...444444...",
  "..44444444..",
  "..44444444..",
  "..44444444..",
  ".4444444444.",
  ".ff444444ff.",
  ".....44.....",
  "............",
], "2", ".");

// tile id -> art. ids are positions in a 10-wide, 12px grid.
const TILES = [
  A.sand, A.dune, A.tuft, A.rock, A.goal, A.waterA, A.waterB,
  A.box, A.boxgoal, A.pebble,
  A.side, A.sidej, A.front, A.frontj, A.back, A.backj,
];

// ------------------------------------------------------------------- __gfx__

const sheet = [];
for (let y = 0; y < 128; y++) sheet.push(new Array(128).fill("0"));

TILES.forEach((art, id) => {
  if (art.length !== 12) throw new Error("tile " + id + " has " + art.length + " rows");
  const ox = (id % 10) * 12, oy = Math.floor(id / 10) * 12;
  art.forEach((row, y) => {
    if (row.length !== 12) throw new Error("tile " + id + " row " + y + " is " + row.length + " wide");
    for (let x = 0; x < 12; x++) {
      const c = row[x];
      if (!/[0-9a-f.]/.test(c)) throw new Error("tile " + id + " bad char '" + c + "'");
      sheet[oy + y][ox + x] = c === "." ? "0" : c;
    }
  });
});

const gfx = sheet.map((r) => r.join(""));
gfx.forEach((l, i) => { if (l.length !== 128) throw new Error("gfx line " + i + " is " + l.length); });

// -------------------------------------------------------------------- __sfx__
// note = [pitch, waveform, volume, effect]; null = rest

const hx = (n) => n.toString(16);
const note = (n) => n ? hx(n[0] >> 4) + hx(n[0] & 15) + hx(n[1]) + hx(n[2]) + hx(n[3]) : "00000";

function sfxline(speed, notes, loopStart, loopEnd) {
  const ns = notes.slice(0, 32);
  while (ns.length < 32) ns.push(null);
  const line = "01" + hx(speed >> 4) + hx(speed & 15) +
    hx((loopStart || 0) >> 4) + hx((loopStart || 0) & 15) +
    hx((loopEnd || 0) >> 4) + hx((loopEnd || 0) & 15) +
    ns.map(note).join("");
  if (line.length !== 168) throw new Error("sfx line is " + line.length);
  return line;
}

const sfx = new Array(38).fill(sfxline(16, []));

// tri 0, tilted saw 1, saw 2, square 3, pulse 4, organ 5, noise 6, phaser 7
const set = (n, line) => { sfx[n] = line; };

// 0,1 hop 1 tile — soft wooden tick
set(0, sfxline(5, [[38, 5, 3, 3], [33, 5, 2, 5]]));
set(1, sfxline(5, [[40, 5, 3, 3], [35, 5, 2, 5]]));
// 2,3 jump 2 tiles — deeper, longer
set(2, sfxline(6, [[31, 5, 4, 3], [26, 0, 3, 5], [22, 0, 2, 5]]));
set(3, sfxline(6, [[33, 5, 4, 3], [28, 0, 3, 5], [24, 0, 2, 5]]));
// 4,5 push box — dry scrape
set(4, sfxline(5, [[20, 6, 3, 0], [18, 6, 3, 5], [16, 6, 2, 5]]));
set(5, sfxline(5, [[22, 6, 3, 0], [19, 6, 3, 5], [17, 6, 2, 5]]));
// 6,7 blocked — muted low bonk
set(6, sfxline(6, [[14, 3, 3, 3], [12, 3, 2, 5]]));
set(7, sfxline(6, [[16, 3, 3, 3], [13, 3, 2, 5]]));
// 8,9 landing thud on sand
set(8, sfxline(4, [[13, 0, 3, 3], [10, 6, 2, 5]]));
set(9, sfxline(4, [[15, 0, 3, 3], [11, 6, 2, 5]]));
// 10,11 player falls in water — plip + descending tail
set(10, sfxline(7, [[36, 5, 4, 3], [28, 0, 3, 1], [22, 0, 3, 1], [16, 0, 2, 5], [12, 6, 2, 5]]));
set(11, sfxline(7, [[34, 5, 4, 3], [27, 0, 3, 1], [21, 0, 3, 1], [15, 0, 2, 5], [11, 6, 2, 5]]));
// 12,13 box falls in water — heavier
set(12, sfxline(8, [[24, 0, 4, 3], [18, 0, 3, 1], [13, 0, 3, 1], [9, 0, 2, 5], [8, 6, 2, 5]]));
set(13, sfxline(8, [[26, 0, 4, 3], [19, 0, 3, 1], [14, 0, 3, 1], [10, 0, 2, 5], [9, 6, 2, 5]]));
// 14,15 level complete — pentatonic rise
set(14, sfxline(9, [[28, 5, 4, 0], [31, 5, 4, 0], [35, 5, 4, 0], [40, 5, 5, 0], [43, 5, 4, 5]]));
set(15, sfxline(9, [[28, 5, 4, 0], [33, 5, 4, 0], [35, 5, 4, 0], [40, 5, 5, 0], [45, 5, 4, 5]]));
// 16,17 menu cursor
set(16, sfxline(4, [[36, 5, 2, 0]]));
set(17, sfxline(4, [[38, 5, 2, 0]]));
// 18,19 menu confirm
set(18, sfxline(6, [[33, 5, 3, 0], [40, 5, 3, 5]]));
set(19, sfxline(6, [[35, 5, 3, 0], [42, 5, 3, 5]]));
// 20,21 restart
set(20, sfxline(6, [[30, 6, 3, 0], [24, 6, 3, 5], [18, 6, 2, 5], [14, 6, 1, 5]]));
set(21, sfxline(6, [[32, 6, 3, 0], [25, 6, 3, 5], [19, 6, 2, 5], [15, 6, 1, 5]]));
// 22,23 undo — quiet reversed-sounding rise
set(22, sfxline(4, [[24, 5, 1, 4], [31, 5, 2, 4], [36, 5, 2, 5]]));
set(23, sfxline(4, [[26, 5, 1, 4], [33, 5, 2, 4], [38, 5, 2, 5]]));

// music beds. pentatonic on A: A C D E G -> 21 24 26 28 31 (+12 per octave)
//
// The bottom voice is a few plucked bass notes, not a sustained drone. A drone
// here is 32 filled steps looping forever, which is one unbroken tone for as
// long as the cart is running — on the pulse wave with vibrato it reads as
// constant noise rather than atmosphere. Triangle with a fade-out (effect 5)
// gives each note a decay, so the low end breathes and then gets out of the way.
const bass = (speed, seq) => {
  const ns = new Array(32).fill(null);
  for (const [i, p, v] of seq) ns[i] = [p, 0, v, 5];
  return sfxline(speed, ns, 0, 32);
};
set(32, bass(20, [[0, 21, 3], [12, 28, 2], [22, 24, 2]]));   // intro / level select
set(35, bass(20, [[0, 21, 2], [16, 26, 2]]));                // in game, sparser still

const melody = (speed, seq) => {
  const ns = new Array(32).fill(null);
  for (const [i, p, v] of seq) ns[i] = [p, 5, v, 5];
  return sfxline(speed, ns, 0, 32);
};
// A tune rather than scattered notes: one pentatonic phrase per pair of
// patterns, a note every four steps (~0.7s at speed 20), rising then settling
// back on the root. 33/34 is the menu phrase; 36/37 answers it an octave lower
// and quieter so it sits under the game sfx instead of competing with them.
set(33, melody(20, [[0, 45, 3], [4, 48, 3], [8, 50, 3], [12, 52, 3], [16, 50, 2], [20, 48, 3], [24, 45, 2], [28, 43, 2]]));
set(34, melody(20, [[0, 45, 3], [4, 50, 3], [8, 52, 3], [12, 55, 3], [16, 52, 2], [20, 50, 3], [24, 48, 2], [28, 45, 2]]));
set(36, melody(20, [[0, 33, 2], [4, 36, 2], [8, 38, 2], [12, 40, 2], [20, 38, 2], [26, 36, 2]]));
set(37, melody(20, [[0, 33, 2], [4, 38, 2], [8, 40, 2], [12, 43, 2], [20, 40, 2], [26, 36, 2]]));

// ------------------------------------------------------------------ __music__
const music = [
  "01 20214344",  // 0: intro/level select, loop start
  "02 20224344",  // 1: loop end
  "01 23244344",  // 2: in game, loop start
  "02 23254344",  // 3: loop end
];

// ------------------------------------------------------------- splice cart
let cart = fs.readFileSync(CART, "utf8").replace(/\r\n/g, "\n");

// level table
const lua = "lvls={\n" + levels.map((s, i) => {
  const rows = [];
  for (let y = 0; y < 10; y++) rows.push('"' + s.slice(y * 10, y * 10 + 10) + '"');
  return "-- " + (i + 1) + "\n" + rows.join("..\n");
}).join(",\n") + "}\n";

const li = cart.indexOf("-- <levels>");
const lj = cart.indexOf("-- </levels>");
if (li < 0 || lj < 0) throw new Error("level markers missing");
cart = cart.slice(0, li) + "-- <levels>\n" + lua + cart.slice(lj);

function section(name, lines) {
  const re = new RegExp("^__" + name + "__$", "m");
  const i = cart.search(re);
  if (i < 0) throw new Error("no __" + name + "__ section");
  const after = cart.slice(i).search(/^__[a-z]+__$/m, 1);
  const rest = cart.slice(i + name.length + 5);
  const nx = rest.search(/^__[a-z]+__$/m);
  const tail = nx < 0 ? "" : rest.slice(nx);
  cart = cart.slice(0, i) + "__" + name + "__\n" + lines.join("\n") + "\n" + tail;
}

section("gfx", gfx);
section("sfx", sfx);
section("music", music);

fs.writeFileSync(CART, cart);

// ------------------------------------------------------------------ preview
function png(pixels, w, h, file) {
  const PAL = ["000000", "1D2B53", "7E2553", "008751", "AB5236", "5F574F", "C2C3C7",
    "FFF1E8", "FF004D", "FFA300", "FFEC27", "00E436", "29ADFF", "83769C", "FF77A8", "FFCCAA"];
  const raw = Buffer.alloc((w * 3 + 1) * h);
  let o = 0;
  for (let y = 0; y < h; y++) {
    raw[o++] = 0;
    for (let x = 0; x < w; x++) {
      const c = PAL[pixels[y][x]];
      raw[o++] = parseInt(c.slice(0, 2), 16);
      raw[o++] = parseInt(c.slice(2, 4), 16);
      raw[o++] = parseInt(c.slice(4, 6), 16);
    }
  }
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
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 2;
  fs.writeFileSync(file, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw)),
    chunk("IEND", Buffer.alloc(0)),
  ]));
}

const S = 4;
const px = [];
for (let y = 0; y < 128 * S; y++) {
  px.push([]);
  for (let x = 0; x < 128 * S; x++) {
    px[y].push(parseInt(gfx[Math.floor(y / S)][Math.floor(x / S)], 16));
  }
}
png(px, 128 * S, 128 * S, path.join(__dirname, "preview.png"));

console.log("gfx  " + gfx.length + " lines");
console.log("sfx  " + sfx.length + " lines, all 168 chars");
console.log("music " + music.length + " patterns");
console.log("levels injected: " + levels.length);
