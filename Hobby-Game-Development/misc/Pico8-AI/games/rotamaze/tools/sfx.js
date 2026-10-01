// rotamaze - sound. dry, small, mechanical: a stone door being shoved.
'use strict';

const h2 = n => n.toString(16).padStart(2, '0');
const h1 = n => n.toString(16);

// note: [pitch, waveform, volume, effect]  -  null = rest
function line(speed, notes, loopStart = 0, loopEnd = 0) {
  const body = [];
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    if (!n) { body.push('00000'); continue; }
    const [p, w, v, e] = n;
    body.push(h2(p) + h1(w) + h1(v) + h1(e || 0));
  }
  const s = '00' + h2(speed) + h2(loopStart) + h2(loopEnd) + body.join('');
  if (s.length !== 168) throw new Error('sfx line width ' + s.length);
  return s;
}

const TRI = 0, SAW = 2, SQR = 3, PUL = 4, ORG = 5, NOI = 6;

const FX = [
  // 0 - blocked. a dry thud: it should say "stop", not "error".
  line(5, [[10, NOI, 5, 0], [6, NOI, 3, 3], [4, TRI, 2, 5]]),
  // 1 - step. barely there, one soft tick.
  line(4, [[14, NOI, 2, 5]]),
  // 2 - rotate. stone grinding round a quarter turn.
  line(5, [[24, SAW, 3, 0], [30, PUL, 4, 3], [18, NOI, 2, 5]]),
  // 3 - rewind. a short slide backwards.
  line(4, [[34, ORG, 4, 1], [27, ORG, 3, 1], [21, ORG, 3, 5]]),
  // 4 - escaped. small fanfare, four notes up.
  line(9, [[21, ORG, 5, 0], [25, ORG, 5, 0], [28, ORG, 5, 0], [33, ORG, 6, 5]]),
];


// ---- music --------------------------------------------------------------
// a slow chorale in a minor, two voices only: sustained melody over a walking
// bass. it takes channels 0 and 1, which leaves 2 and 3 free so a step or a
// rotation never has to interrupt the music to be heard.
const MSPEED = 30;          // 30/128s a tick - eight ticks, ~1.9s, per chord
const MFIRST = FX.length;   // the music sfx sit straight after the effects

// [pitch, ticks] pairs, one note per tick: repeating a pitch is how pico-8
// holds a note, and four chords of eight ticks fill a 32-tick pattern
function voice(seq, wave, vol) {
  const notes = [];
  for (const [p, n] of seq) for (let i = 0; i < n; i++) notes.push([p, wave, vol, 0]);
  if (notes.length !== 32) throw new Error('voice is ' + notes.length + ' ticks, want 32');
  return line(MSPEED, notes);
}

// harmony, one line per pattern:
//   am e  f  c | dm am dm e | am e f c | dm am e am
const MELODY = [
  [[52, 4], [48, 4], [47, 8], [48, 4], [45, 4], [43, 8]],
  [[41, 4], [45, 4], [48, 8], [50, 4], [48, 4], [47, 8]],
  [[45, 4], [48, 4], [52, 4], [47, 4], [45, 4], [41, 4], [43, 4], [40, 4]],
  [[41, 8], [40, 4], [45, 4], [44, 8], [45, 8]],   // g# leans back into a
];
// root, then fifth, under each chord
const BASS = [
  [[21, 4], [28, 4], [16, 4], [23, 4], [17, 4], [24, 4], [12, 4], [19, 4]],
  [[14, 4], [21, 4], [21, 4], [28, 4], [14, 4], [21, 4], [16, 4], [23, 4]],
  [[21, 4], [28, 4], [16, 4], [23, 4], [17, 4], [24, 4], [12, 4], [19, 4]],
  [[14, 4], [21, 4], [21, 4], [28, 4], [16, 4], [23, 4], [21, 8]],
];

const MUSIC_SFX = [];
MELODY.forEach((m, i) => {
  MUSIC_SFX.push(voice(m, TRI, 5));        // melody -> channel 0
  MUSIC_SFX.push(voice(BASS[i], ORG, 3));  // bass   -> channel 1
});

// pattern line: flags, then one byte per channel. flag 1 starts the loop and
// 2 ends it; 42/43 have bit 6 set, which parks channels 2 and 3 as unused.
const MUSIC = MELODY.map((_, i) => {
  const f = i === 0 ? 1 : (i === MELODY.length - 1 ? 2 : 0);
  return h2(f) + ' ' + h2(MFIRST + i * 2) + h2(MFIRST + i * 2 + 1) + '4243';
});

const SFX = FX.concat(MUSIC_SFX);

module.exports = { SFX, MUSIC };
if (require.main === module) {
  SFX.forEach((l, i) => console.log(i, l.length, l.slice(0, 40)));
  MUSIC.forEach((l, i) => console.log('pat', i, l));
  const secs = MUSIC.length * 32 * MSPEED / 128;
  console.log('loop', secs.toFixed(1) + 's');
}
