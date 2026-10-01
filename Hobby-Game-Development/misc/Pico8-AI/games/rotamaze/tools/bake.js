// rotamaze - write sprites, sound and the 64-maze pool into game.p8.
// the maze pool lives in the 8k that runs from 0x1000 (gfx lines 64..127,
// i.e. sprites 128..255) straight into 0x2000 (the map). 64 mazes x 110
// bytes = 7040 bytes, so it fits with room to spare.
//   node bake.js [mazes.json]
'use strict';
const fs = require('fs');
const path = require('path');
const art = require('./art.js');
const { SFX, MUSIC } = require('./sfx.js');

const CART = path.join(__dirname, '..', 'game.p8');
const REC = 110;                       // bytes per maze record
const ORDER = ['lua', 'gfx', 'label', 'gff', 'map', 'sfx', 'music'];

function parseCart(txt) {
  const lines = txt.split(/\r?\n/);
  const head = [];
  const sec = {};
  let cur = null;
  for (const ln of lines) {
    const m = /^__(\w+)__$/.exec(ln);
    if (m) { cur = m[1]; sec[cur] = []; continue; }
    if (cur) sec[cur].push(ln); else head.push(ln);
  }
  for (const k in sec) {
    while (sec[k].length && sec[k][sec[k].length - 1] === '') sec[k].pop();
  }
  return { head, sec };
}

function packMazes(mazes) {
  if (mazes.length !== 64) throw new Error('need exactly 64 mazes, got ' + mazes.length);
  const mem = new Uint8Array(8192);
  mazes.forEach((m, mi) => {
    const base = mi * REC;
    for (let i = 0; i < 210; i++) {
      const w = m.board[i] & 15;
      if (i % 2 === 0) mem[base + (i >> 1)] |= w;
      else mem[base + (i >> 1)] |= w << 4;
    }
    for (const [off, v] of [[105, m.start], [106, m.exit], [107, m.face],
    [108, m.movBudget], [109, m.actBudget]]) {
      if (v < 0 || v > 255) throw new Error('field out of byte range: ' + v);
      mem[base + off] = v;
    }
  });
  return mem;
}

const h1 = n => n.toString(16);
const h2 = n => n.toString(16).padStart(2, '0');

// bytes 0..4095 of the pool -> gfx lines 64..127 (low nibble is the left pixel)
function gfxData(mem) {
  const out = [];
  for (let l = 0; l < 64; l++) {
    let s = '';
    for (let b = 0; b < 64; b++) {
      const v = mem[l * 64 + b];
      s += h1(v & 15) + h1(v >> 4);
    }
    out.push(s);
  }
  return out;
}

// bytes 4096..8191 -> map lines 0..31 (plain byte order)
function mapData(mem) {
  const out = [];
  for (let l = 0; l < 32; l++) {
    let s = '';
    for (let b = 0; b < 128; b++) s += h2(mem[4096 + l * 128 + b]);
    out.push(s);
  }
  while (out.length && /^0+$/.test(out[out.length - 1])) out.pop();
  return out;
}

function assertWidths(name, lines, w) {
  lines.forEach((l, i) => {
    if (l.length !== w) throw new Error(name + ' line ' + i + ' is ' + l.length + ', want ' + w);
  });
}

function main() {
  const src = process.argv[2] || path.join(__dirname, 'mazes.json');
  const mazes = JSON.parse(fs.readFileSync(src, 'utf8'));
  const mem = packMazes(mazes);

  const { head, sec } = parseCart(fs.readFileSync(CART, 'utf8'));
  const gfx = art.gfxArt().concat(gfxData(mem));
  const map = mapData(mem);
  assertWidths('gfx', gfx, 128);
  assertWidths('map', map, 256);
  assertWidths('sfx', SFX, 168);
  if (gfx.length !== 128) throw new Error('gfx must be 128 lines');

  sec.gfx = gfx;
  sec.map = map;
  sec.sfx = SFX;
  delete sec.gff;
  sec.music = MUSIC;

  const out = [head.join('\n').replace(/\n+$/, '')];
  for (const k of ORDER) {
    if (!sec[k]) continue;
    out.push('__' + k + '__');
    out.push(sec[k].join('\n'));
  }
  fs.writeFileSync(CART, out.join('\n') + '\n');

  // ---- round trip: read the cart back and rebuild the maze pool from it
  const back = parseCart(fs.readFileSync(CART, 'utf8'));
  const mem2 = new Uint8Array(8192);
  back.sec.gfx.slice(64).forEach((l, i) => {
    for (let b = 0; b < 64; b++) {
      mem2[i * 64 + b] = parseInt(l[b * 2 + 1] + l[b * 2], 16);
    }
  });
  (back.sec.map || []).forEach((l, i) => {
    for (let b = 0; b < 128; b++) mem2[4096 + i * 128 + b] = parseInt(l.substr(b * 2, 2), 16);
  });
  for (let i = 0; i < 8192; i++) {
    if (mem[i] !== mem2[i]) throw new Error('round trip differs at byte ' + i);
  }
  mazes.forEach((m, mi) => {
    const base = mi * REC;
    for (let i = 0; i < 210; i++) {
      const b = mem2[base + (i >> 1)];
      const w = i % 2 === 0 ? b & 15 : b >> 4;
      if (w !== m.board[i]) throw new Error('maze ' + mi + ' tile ' + i + ' differs');
    }
    if (mem2[base + 105] !== m.start || mem2[base + 106] !== m.exit ||
      mem2[base + 107] !== m.face || mem2[base + 108] !== m.movBudget ||
      mem2[base + 109] !== m.actBudget) throw new Error('maze ' + mi + ' header differs');
  });

  const used = 64 * REC;
  console.log('baked', mazes.length, 'mazes,', used, 'bytes of 8192 (0x1000..0x' +
    (0x1000 + used).toString(16) + ')');
  console.log('gfx lines', gfx.length, 'map lines', map.length, 'sfx', SFX.length, 'music patterns', MUSIC.length);
  console.log('mov budgets', Math.min(...mazes.map(m => m.movBudget)), '-', Math.max(...mazes.map(m => m.movBudget)));
  console.log('act budgets', Math.min(...mazes.map(m => m.actBudget)), '-', Math.max(...mazes.map(m => m.actBudget)));
  console.log('round trip ok');
}
main();
