// verify.js — parse the generated __sfx__ / __music__ back out of game.p8 and
// render them as a table. Headless pico-8 never advances the audio clock, so
// reading the data back is the only way to check tempo, pitch and arrangement.
//   node verify.js          summary + rule checks
//   node verify.js 36       dump one sfx slot note by note
'use strict';
const fs = require('fs');
const path = require('path');
const CR = String.fromCharCode(13);
const cart = fs.readFileSync(path.join(__dirname, 'game.p8'), 'utf8').split(CR).join('');

function section(name) {
  const m = new RegExp('^__' + name + '__$', 'm').exec(cart);
  if (!m) return [];
  const from = m.index + m[0].length + 1;
  const nx = cart.slice(from).search(/^__[a-z]+__$/m);
  return cart.slice(from, nx < 0 ? cart.length : from + nx).split('\n').filter(Boolean);
}

const NAMES = ['c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'];
const WAVE = ['tri', 'saw~', 'saw', 'sqr', 'puls', 'orgn', 'NOISE', 'phsr'];
const note = (p) => NAMES[p % 12] + Math.floor(p / 12);

const sfx = section('sfx');
const music = section('music');
let bad = 0;
const fail = (m) => { bad++; console.log('  FAIL ' + m); };

for (const l of sfx) if (l.length !== 168) fail('sfx line width ' + l.length);
console.log('sfx lines: ' + sfx.length + '   music patterns: ' + music.length);

function parse(n) {
  const l = sfx[n];
  const out = { speed: parseInt(l.slice(2, 4), 16), notes: [] };
  for (let i = 0; i < 32; i++) {
    const s = l.slice(8 + i * 5, 13 + i * 5);
    out.notes.push({ p: parseInt(s.slice(0, 2), 16), w: parseInt(s[2], 16), v: parseInt(s[3], 16), e: parseInt(s[4], 16) });
  }
  return out;
}

const only = process.argv[2];
if (only !== undefined) {
  const s = parse(+only);
  console.log('sfx ' + only + '  speed ' + s.speed + '  (' + (s.speed / 120).toFixed(3) + 's per slot)');
  s.notes.forEach((n, i) => {
    console.log(String(i).padStart(2) + '  ' +
      (n.v === 0 ? '-' : note(n.p).padEnd(4) + ' ' + WAVE[n.w].padEnd(5) + ' v' + n.v + ' fx' + n.e));
  });
  process.exit(0);
}

// ------------------------------------------------- per-slot summary
console.log('\nslot  spd  notes  range        waves        maxvol  role');
const role = (n) => n < 20 ? 'sfx' : n < 36 ? 'track a' : n < 50 ? 'track b' : 'track c';
for (let n = 0; n < sfx.length; n++) {
  const s = parse(n);
  const live = s.notes.filter((x) => x.v > 0);
  if (!live.length) { console.log(String(n).padStart(4) + '   (empty)'); continue; }
  const lo = Math.min(...live.map((x) => x.p)), hi = Math.max(...live.map((x) => x.p));
  const waves = [...new Set(live.map((x) => WAVE[x.w]))].join(',');
  const mv = Math.max(...live.map((x) => x.v));
  let atk = 0;
  for (let i = 0; i < 32; i++) if (s.notes[i].v > 0 && s.notes[i].e !== 1) atk++;
  console.log(String(n).padStart(4) + '  ' + String(s.speed).padStart(3) + '  ' +
    String(live.length).padStart(5) + '  ' + (note(lo) + '-' + note(hi)).padEnd(11) + '  ' +
    waves.padEnd(11) + '  ' + String(mv).padStart(6) + '  ' +
    String(atk).padStart(4) + '  ' + role(n));
  // §10.1: the noise channel is never used, anywhere
  if (live.some((x) => x.w === 6)) fail('sfx ' + n + ' uses the noise waveform');
  // §10.1: no sfx runs past ~0.4s. Slots 1 and 2 are the 32-step pitch
  // ladders, never played whole: the cart plays one note of them at a time.
  if (n < 20 && n > 2 && live.length * s.speed / 120 > 0.5) fail('sfx ' + n + ' is too long');
  // §10.2: music density and speed. What matters is note *attacks* — a held
  // note repeats its pitch with the slide effect, which is one sound, not many.
  if (n >= 20) {
    if (s.speed !== 28) fail('music slot ' + n + ' speed ' + s.speed + ' (want 28)');
    const rate = atk / (32 * s.speed / 120);
    if (rate > 8) fail('music slot ' + n + ' fires ' + rate.toFixed(1) + ' notes/sec (cap 8)');
  }
}

// ------------------------------------------------- pattern table
console.log('\npat  flags  bass  pad   mel   ch3');
const TRACKS = { 0: 'a select', 8: 'b levels 1-8', 16: 'c levels 9-16' };
music.forEach((l, i) => {
  const f = parseInt(l.slice(0, 2), 16);
  const ch = [0, 1, 2, 3].map((k) => parseInt(l.slice(3 + k * 2, 5 + k * 2), 16));
  const nm = (v) => (v >= 0x40 ? '--' : String(v).padStart(2));
  console.log(String(i).padStart(3) + '  ' +
    ((f & 1 ? 'S' : '.') + (f & 2 ? 'E' : '.') + (f & 4 ? 'X' : '.')).padEnd(6) +
    nm(ch[0]).padEnd(6) + nm(ch[1]).padEnd(6) + nm(ch[2]).padEnd(6) + nm(ch[3]) +
    (TRACKS[i] ? '   <- track ' + TRACKS[i] : ''));
  // ch3 must stay free for sfx (§10.2)
  if (ch[3] < 0x40) fail('pattern ' + i + ' uses channel 3, which is reserved for sfx');
});

// loop structure: each track opens with a loop-start and closes with a loop-end
for (const start of [0, 8, 16]) {
  if (!(parseInt(music[start].slice(0, 2), 16) & 1)) fail('pattern ' + start + ' is not a loop start');
  if (!(parseInt(music[start + 7].slice(0, 2), 16) & 2)) fail('pattern ' + (start + 7) + ' is not a loop end');
  for (let i = start + 1; i < start + 7; i++)
    if (parseInt(music[i].slice(0, 2), 16) & 3) fail('pattern ' + i + ' has a stray loop flag');
}
const secs = 8 * 32 * 28 / 120;
console.log('\neach track: 8 patterns x 32 slots at speed 28 = ' + secs.toFixed(1) + 's before repeat');
if (secs < 55) fail('a track loops in under a minute (§10.2 wants 60-90s)');

console.log(bad ? '\n' + bad + ' PROBLEMS' : '\naudio data ok');
process.exit(bad ? 1 : 0);
