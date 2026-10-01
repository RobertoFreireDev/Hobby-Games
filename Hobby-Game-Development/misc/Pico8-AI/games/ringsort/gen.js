// gen.js -- generates __gfx__, __sfx__ and __music__ for ring sort and splices
// them into game.p8. Everything else in the cart (the Lua, the label) is passed
// through untouched.
//
// usage: node gen.js [game.p8]
'use strict';
const fs = require('fs');
const ART = require('./ringart');

// ===================================================================== sprites
//
// The sheet is deliberately tiny: one ring template recoloured seven ways by
// pal() at draw time, one pip, and seven bits of UI. Everything else (pillars,
// bases, plates, vignette, logo) is drawn with primitives and P8SCII wide/tall
// text, which costs tokens instead of sprite space and stays crisp.
//
// '1' is the transparent colour (the cart runs palt(0,false) palt(1,true) so
// black can be used as an outline).

const X = [ // 5: red x for the rule plates
  '11111111',
  '18811881',
  '18888881',
  '11888811',
  '11888811',
  '18888881',
  '18811881',
  '11111111'];

const LOCK = [ // 6: padlock on a locked level
  '11111111',
  '11666611',
  '16511561',
  '16111161',
  '16666661',
  '16500561',
  '16500561',
  '15555551'];

const PIPF = [ // 7: cleared-level pip
  '11111111',
  '11119111',
  '111a9111',
  '11aaa911',
  '1aaaa911',
  '11aa9111',
  '111a9111',
  '11111111'];

const PIPE = [ // 8: uncleared-level pip
  '11111111',
  '11115111',
  '11151511',
  '11511151',
  '15111151',
  '11511511',
  '11151111',
  '11111111'];

const ARROW = [ // 9: level-select arrow (flipped for the right one)
  '11101111',
  '11071111',
  '10771111',
  '07771111',
  '07771111',
  '10771111',
  '11071111',
  '11101111'];

const CUR = [ // 10: cursor chevron under the selected pillar
  '11100111',
  '110aa011',
  '10aaaa01',
  '0aa00aa0',
  '0a0110a0',
  '10111101',
  '11111111',
  '11111111'];

// The playing piece is a 24x9 ellipsoid creature living at (0,0) as a free-form
// sspr region, not on the sprite grid. Its scowling and blinking twins sit
// directly below at (0,9) and (0,18), so dring picks a face with one sy offset
// and nothing else changes. The 8x8 UI sprites keep their grid slots from x=32.
const RING_W = 24, RING_H = 9;

const SHEET_H = 32;
const sheet = [];
for (let y = 0; y < SHEET_H; y++) sheet.push(new Array(128).fill('0'));

function blit(rows, sx, w, sy) {
  sy = sy || 0;
  rows.forEach((r, y) => {
    if (r.length !== w) throw new Error('sprite at ' + sx + ' row ' + y + ' width ' + r.length);
    for (let x = 0; x < w; x++) sheet[sy + y][sx + x] = r[x];
  });
}

blit(ART.blob('calm'), 0, RING_W);                             // sspr(0,0,24,9)
blit(ART.blob('angry'), 0, RING_W, RING_H);                    // sspr(0,9,24,9)
blit(ART.blob('blink'), 0, RING_W, RING_H * 2);                // sspr(0,18,24,9)
blit(ART.pip(true), 24, 8);                                    // spr 3
blit(ART.pip(false), 32, 8);                                   // spr 4
blit(X, 40, 8);                                                // spr 5
blit(LOCK, 48, 8);                                             // spr 6
blit(PIPF, 56, 8);                                             // spr 7
blit(PIPE, 64, 8);                                             // spr 8
blit(ARROW, 72, 8);                                            // spr 9
blit(CUR, 80, 8);                                              // spr 10

const gfx = sheet.map((r) => {
  const s = r.join('');
  if (s.length !== 128) throw new Error('gfx line width ' + s.length);
  return s;
});

// ======================================================================== sfx

function sfxline(speed, notes, loopS, loopE) {
  let s = '00' + hx(speed) + hx(loopS || 0) + hx(loopE || 0);
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    if (!n || n[2] === 0) { s += '00000'; continue; }
    if (n[0] < 0 || n[0] > 63) throw new Error('pitch out of range: ' + n[0]);
    if (n[1] === 6) throw new Error('noise waveform is banned (design 6.2/9)');
    if (n[2] > 7) throw new Error('volume out of range');
    s += hx(n[0]) + n[1].toString(16) + n[2].toString(16) + n[3].toString(16);
  }
  if (s.length !== 168) throw new Error('sfx width ' + s.length);
  return s;
}
const hx = (v) => v.toString(16).padStart(2, '0');

// ---- game sounds, design 6.2. warm palette, no noise anywhere.
const GAME_SFX = {
  0:  sfxline(4,  [[52, 5, 2, 0]]),                                            // cursor move
  1:  sfxline(5,  [[36, 0, 4, 0], [43, 0, 4, 0], [48, 0, 3, 5]]),              // ring lift
  2:  sfxline(6,  [[24, 4, 5, 0], [31, 0, 3, 5]]),                             // drop, low stack
  3:  sfxline(6,  [[27, 4, 5, 0], [34, 0, 3, 5]]),                             // drop, mid
  4:  sfxline(6,  [[30, 4, 5, 0], [37, 0, 3, 5]]),                             // drop, high
  5:  sfxline(6,  [[43, 5, 3, 0], [38, 5, 3, 5]]),                             // cancel
  6:  sfxline(9,  [[26, 5, 4, 3], [20, 5, 4, 3]]),                             // BLOCKED
  7:  sfxline(3,  [[30, 0, 2, 5]]),                                            // empty pillar
  8:  sfxline(6,  [[48, 4, 5, 0], [52, 4, 5, 0], [55, 4, 5, 0], [60, 4, 6, 5]]), // pillar done
  9:  sfxline(7,  [[36, 4, 5, 0], [40, 4, 5, 0], [43, 4, 5, 0], [48, 4, 6, 0],
                   [52, 4, 6, 0], [55, 4, 6, 0], [59, 4, 5, 0], [60, 4, 5, 5]]), // level complete
  10: sfxline(5,  [[43, 4, 4, 0], [50, 4, 5, 5]]),                             // menu confirm
  11: sfxline(5,  [[45, 4, 4, 0], [38, 4, 4, 5]]),                             // menu back
  12: sfxline(3,  [[40, 0, 3, 0], [36, 0, 2, 5]]),                             // level tick
  13: sfxline(3,  [[48, 5, 3, 0], [53, 5, 3, 0], [58, 5, 4, 0], [63, 5, 4, 0], [63, 5, 2, 5]]), // shimmer
  14: sfxline(16, [[33, 5, 3, 0], [30, 5, 3, 0], [0, 0, 0, 0], [26, 5, 2, 5]]), // no moves left
  15: sfxline(3,  [[55, 5, 2, 4], [60, 5, 2, 0], [63, 5, 1, 5]]),              // title shine
};

// ====================================================================== music
//
// Original writing in the idiom the design asks for (Bach-prelude arpeggio
// figures, Satie-sparse voicing) rather than a transcription. Three channels:
//
//   ch0 arpeggio  organ    vol 2   constant gentle motion
//   ch1 bass      triangle vol 4   root, two breaths per pattern
//   ch2 melody    pulse    vol 3   sparse, voice-led
//
// Channel 3 is left free on purpose so gameplay SFX always sit above the bed
// (design 6.2) -- music() is called with a channel mask of 7.

const NOTE = { c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11 };
function n(s) {
  const m = /^([a-g])([#b]?)(\d)$/.exec(s);
  if (!m) throw new Error('bad note ' + s);
  return NOTE[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0) + (+m[3]) * 12;
}
const N = (a) => a.map(n);

// chord = { bass, arp[4], tones[] } -- tones feed the melody
const CH = {
  C:   { bass: n('c2'), arp: N(['c3', 'e3', 'g3', 'c4']), tones: N(['c4', 'e4', 'g4', 'c5']) },
  Am:  { bass: n('a1'), arp: N(['a2', 'c3', 'e3', 'a3']), tones: N(['a3', 'c4', 'e4', 'a4']) },
  Dm7: { bass: n('d2'), arp: N(['d3', 'f3', 'a3', 'c4']), tones: N(['d4', 'f4', 'a4', 'c5']) },
  G7:  { bass: n('g1'), arp: N(['g2', 'b2', 'd3', 'f3']), tones: N(['b3', 'd4', 'f4', 'g4']) },
  G:   { bass: n('g1'), arp: N(['g2', 'd3', 'g3', 'b3']), tones: N(['b3', 'd4', 'g4', 'b4']) },
  Em:  { bass: n('e2'), arp: N(['e3', 'g3', 'b3', 'e4']), tones: N(['b3', 'e4', 'g4', 'b4']) },
  F:   { bass: n('f2'), arp: N(['f3', 'a3', 'c4', 'f4']), tones: N(['c4', 'f4', 'a4', 'c5']) },
  Dm:  { bass: n('d2'), arp: N(['d3', 'f3', 'a3', 'd4']), tones: N(['d4', 'f4', 'a4', 'd5']) },
  E7:  { bass: n('e2'), arp: N(['e3', 'g#3', 'b3', 'd4']), tones: N(['b3', 'd4', 'e4', 'g#4']) },
  Fm7: { bass: n('f2'), arp: N(['f3', 'a3', 'c4', 'e4']), tones: N(['c4', 'e4', 'f4', 'a4']) },
};

for (const [name, c] of Object.entries(CH)) {
  for (const p of [c.bass].concat(c.arp, c.tones)) {
    if (p < 0 || p > 63) throw new Error('chord ' + name + ': pitch ' + p + ' outside 0..63');
  }
}

function rng(seed) {
  let a = seed;
  return () => {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// A Bach-prelude style broken chord: rise, hover, resolve. Eight steps, four
// times over the 32-step pattern.
function arpChan(ch, wave, vol) {
  const a = ch.arp;
  const fig = [a[0], a[1], a[2], a[3], a[2], a[1], a[2], a[3]];
  const out = [];
  for (let i = 0; i < 32; i++) out.push([fig[i % 8], wave, vol, 0]);
  return out;
}

// Root note, attacked twice per pattern and sustained with effect 1 (slide to
// the same pitch), which is how you hold a note in PICO-8 without a retrigger
// click on every step.
function bassChan(ch, wave, vol) {
  const out = new Array(32).fill(null);
  for (const start of [0, 16]) {
    out[start] = [ch.bass, wave, vol, 0];
    for (let i = 1; i < 12; i++) out[start + i] = [ch.bass, wave, vol, 1];
    for (let i = 12; i < 16; i++) out[start + i] = null; // breath
  }
  return out;
}

// Sparse melody, voice-led: each note is the chord tone closest to the last one,
// so the line steps rather than leaping. Held notes use slide, same as the bass.
function melChan(ch, wave, vol, rhythm, r, state) {
  const out = new Array(32).fill(null);
  for (let i = 0; i < rhythm.length; i++) {
    const at = rhythm[i];
    const len = (rhythm[i + 1] || 32) - at;
    let cand = ch.tones;
    if (state.last !== null) {
      cand = cand.slice().sort((x, y) => Math.abs(x - state.last) - Math.abs(y - state.last));
      // usually step to the nearest tone, occasionally reach for the next one
      cand = r() < 0.72 ? [cand[0], cand[1]] : [cand[1], cand[2]];
    }
    const p = cand[(r() * cand.length) | 0];
    state.last = p;
    out[at] = [p, wave, vol, 0];
    for (let j = 1; j < len - 1; j++) out[at + j] = [p, wave, vol, 1];
  }
  return out;
}

const RHYTHMS = [
  [0, 8, 16, 24], [0, 6, 16, 22], [0, 12, 20], [0, 8, 14, 24],
  [0, 10, 16, 26], [0, 16], [0, 6, 12, 20, 26], [0, 8, 20],
];

// slot pool: 0..15 are the game sounds, so the bed lives in 16..63
const pool = [];
const bySrc = new Map();
function slot(line) {
  if (bySrc.has(line)) return bySrc.get(line);
  const id = 16 + pool.length;
  if (id > 63) throw new Error('out of sfx slots for the music bed');
  pool.push(line);
  bySrc.set(line, id);
  return id;
}

// build one track; returns the list of {ch0,ch1,ch2} pattern rows
function track(prog, speed, seed, opt) {
  opt = opt || {};
  const r = rng(seed);
  const state = { last: null };
  return prog.map((name, i) => {
    const ch = CH[name];
    if (!ch) throw new Error('unknown chord ' + name);
    const rows = [];
    rows.push(slot(sfxline(speed, arpChan(ch, 5, opt.arpVol || 2))));
    rows.push(slot(sfxline(speed, bassChan(ch, 0, 4))));
    if (opt.melody === false) rows.push(null);
    else rows.push(slot(sfxline(speed, melChan(ch, 4, 3, RHYTHMS[i % RHYTHMS.length], r, state))));
    return rows;
  });
}

// title: slow, sparse, no melody line -- the arpeggio carries it
const TITLE = track(['C', 'Am', 'F', 'G'], 30, 7001, { melody: false, arpVol: 3 });
// gameplay A, levels 1-10: C major, warm
const GAME_A = track(['C', 'Am', 'Dm7', 'G7', 'Em', 'Am', 'F', 'G'], 26, 7002);
// gameplay B, levels 11-20: same mood, minor-key variation
const GAME_B = track(['Am', 'F', 'C', 'G', 'Dm', 'Am', 'E7', 'Am'], 26, 7003);
// level complete: short flourish, no loop
const WIN = track(['F', 'C'], 20, 7004, { arpVol: 3 });

const music = [];
function addTrack(rows, at, flags) {
  while (music.length < at) music.push('00 41424344');
  rows.forEach((row, i) => {
    const f = flags(i, rows.length);
    const cells = [row[0], row[1], row[2], null]
      .map((s, c) => (s === null || s === undefined ? (0x41 + c).toString(16) : hx(s)))
      .join('');
    music.push(hx(f) + ' ' + cells);
  });
}
const loop = (i, len) => (i === 0 ? 1 : 0) | (i === len - 1 ? 2 : 0);
addTrack(TITLE, 0, loop);
addTrack(GAME_A, 4, loop);
addTrack(GAME_B, 12, loop);
addTrack(WIN, 20, (i, len) => (i === len - 1 ? 4 : 0));

for (const m of music) {
  if (!/^[0-9a-f]{2} [0-9a-f]{8}$/.test(m)) throw new Error('bad music row ' + m);
}

// ===================================================================== splice

const sfxBody = [];
for (let i = 0; i < 16; i++) sfxBody.push(GAME_SFX[i] || sfxline(0, []));
pool.forEach((l) => sfxBody.push(l));

const path = process.argv.slice(2).find((a) => !a.startsWith('--')) || 'game.p8';
const lines = fs.readFileSync(path, 'utf8').replace(/\r\n/g, '\n').split('\n');
const mark = /^__(gfx|label|gff|map|sfx|music)__$/;
const sec = {};
lines.forEach((l, i) => { const m = l.match(mark); if (m) sec[m[1]] = i; });
for (const k of ['gfx', 'sfx', 'music']) {
  if (sec[k] === undefined) throw new Error('cart is missing __' + k + '__');
}
const body = (start) => {
  let e = start + 1;
  while (e < lines.length && !mark.test(lines[e]) && lines[e].trim() !== '') e++;
  return [start + 1, e];
};
// back to front, so an earlier splice cannot shift a later section's index
// --gfx rewrites only the sprite sheet; the score is musicgen.js's job now
const only = process.argv.includes('--gfx')
  ? [['gfx', gfx]]
  : [['music', music], ['sfx', sfxBody], ['gfx', gfx]];
for (const [k, rows] of only
  .sort((a, b) => sec[b[0]] - sec[a[0]])) {
  const [a, b] = body(sec[k]);
  lines.splice(a, b - a, ...rows);
}
fs.writeFileSync(path, lines.join('\n'));

console.log('gfx  : ' + gfx.length + ' lines');
if (!process.argv.includes('--gfx')) {
  console.log('sfx  : 16 game sounds + ' + pool.length + ' bed slots (16..' + (15 + pool.length) + ')');
  console.log('music: ' + music.length + ' patterns');
}
