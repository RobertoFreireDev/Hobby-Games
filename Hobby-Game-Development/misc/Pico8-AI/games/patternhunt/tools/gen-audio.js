// gen-audio.js — builds the __sfx__ and __music__ sections of game.p8
// and splices them in.  Node only (no Python on this machine).
//
//   node gen-audio.js
//
// Design constraints enforced here:
//  - waveform 6 (noise) is BANNED everywhere in this cart.
//  - music lives on channels 0-2, sfx on channel 3.
//  - EVERYTHING is in c# minor.  nt() refuses a pitch outside the key
//    unless it is written through free().
//  - the checks at the bottom of the music section are the real spec:
//    no note may repeat inside a bar, no two bars may be identical, and
//    no two voices may sound a semitone / major 7th apart in the same
//    slot.  If a hand edit breaks one of those, the build fails.
//  - sfx 0, 1, 2 and 4 are "pitch ladders": one slot holding a run of
//    pitches, played a single note at a time via sfx(n, 3, k, 1).

const fs = require('fs');

const NAME = { c: 0, cs: 1, d: 2, ds: 3, e: 4, f: 5, fs: 6, g: 7, gs: 8, a: 9, as: 10, b: 11 };
const PCNAME = Object.fromEntries(Object.entries(NAME).map(([k, v]) => [v, k]));

// pitch number = semitones from C-0; 0..63
function P(n, oct) {
  const p = NAME[n] + oct * 12;
  if (p < 0 || p > 63) throw new Error(`pitch out of range: ${n}-${oct} = ${p}`);
  return p;
}
const pname = (p) => PCNAME[p % 12] + Math.floor(p / 12);

// c# minor, with the harmonic-minor leading tone b# (spelled c) allowed so
// the G#7 chord can exist.  Everything else is off-key by definition.
const KEY = new Set([1, 3, 4, 6, 8, 9, 11, 0]);
let FREE = false;
const free = (f) => { FREE = true; const r = f(); FREE = false; return r; };

const h2 = (v) => v.toString(16).padStart(2, '0');
const h1 = (v) => v.toString(16);

// one note = [pitch:2][waveform:1][volume:1][effect:1]
function nt(pitch, wave, vol, eff = 0) {
  if (wave === 6) throw new Error('waveform 6 (noise) is banned in this cart');
  if (vol === 0 || pitch == null) return '00000';
  if (vol < 0 || vol > 7) throw new Error('volume out of range: ' + vol);
  if (!FREE && !KEY.has(pitch % 12)) {
    throw new Error(`${PCNAME[pitch % 12]} is not in c# minor (pitch ${pitch})`);
  }
  return h2(pitch) + h1(wave) + h1(vol) + h1(eff);
}
const REST = '00000';

// one sfx line = [mode:2][speed:2][loop_start:2][loop_end:2] + 32 notes
function sfxline(speed, notes, loopS = 0, loopE = 0, mode = 1) {
  if (speed < 1 || speed > 255) throw new Error('speed out of range');
  if (notes.length > 32) throw new Error('more than 32 notes');
  const body = [];
  for (let i = 0; i < 32; i++) body.push(notes[i] || REST);
  const s = h2(mode) + h2(speed) + h2(loopS) + h2(loopE) + body.join('');
  if (s.length !== 168) throw new Error(`sfx line is ${s.length} chars, want 168`);
  return s;
}

const SFX = [];
const put = (i, line) => { SFX[i] = line; };

// ---------------------------------------------------------------- interaction
// all of these sound *over* the music bed, so they are c# minor pentatonic
// (c# e f# g# b) or plain chord tones — never a c-major run.

// 00 cursor move — a ladder, not a single pitch.  The game indexes it by
// the cursor's grid row (sfx(0,3,row,1)), so walking the 10-row grid
// traces a pentatonic scale instead of ticking the same note every step.
// This is the most frequently heard sound in the cart by a wide margin.
const CURS = [
  ['b', 4], ['gs', 4], ['fs', 4], ['e', 4], ['cs', 4],
  ['b', 3], ['gs', 3], ['fs', 3], ['e', 3], ['cs', 3],
];
put(0, sfxline(5, CURS.map(([n, o]) => nt(P(n, o), 0, 2))));

// 01 select   — ascending organ pluck ladder, indexed by selection size
// 02 deselect — the same ladder falling
const LADDER = ['cs', 'e', 'fs', 'gs', 'b', 'cs', 'e', 'fs'];
const LADOCT = [3, 3, 3, 3, 3, 4, 4, 4];
const up = LADDER.map((n, i) => nt(P(n, LADOCT[i]), 5, 4));
put(1, sfxline(6, up));
put(2, sfxline(6, up.slice().reverse()));

// 03 submit — short downward phaser glide, the "committed" sound
put(3, sfxline(8, [
  nt(P('gs', 3), 7, 5, 1),
  nt(P('cs', 3), 7, 5, 1),
  nt(P('gs', 2), 7, 4, 1),
]));

// 04 digit lands in score — bright pulse tick ladder, one note per arrival
const LAND = ['cs', 'e', 'gs', 'b', 'cs', 'e', 'gs', 'cs'];
const LANDOCT = [3, 3, 3, 3, 4, 4, 4, 5];
put(4, sfxline(4, LAND.map((n, i) => nt(P(n, LANDOCT[i]), 4, 4))));

// 05 pattern locked — warm rising c#m arpeggio, the round's moment of relief
put(5, sfxline(9, [
  nt(P('cs', 2), 5, 5),
  nt(P('e', 2), 5, 5),
  nt(P('gs', 2), 5, 6),
  nt(P('cs', 3), 5, 6),
]));

// 06 lose — low descending chromatic dyad, square + vibrato, sinking.
// the one place a note is *meant* to fall outside the key.
put(6, free(() => sfxline(20, [
  nt(P('gs', 1), 3, 5, 2),
  nt(P('g', 1), 3, 5, 2),
  nt(P('ds', 1), 3, 4, 2),
  nt(P('d', 1), 3, 4, 2),
  nt(P('cs', 1), 3, 3, 2),
  nt(P('c', 1), 3, 2, 2),
])));

// 07 win — flourish lifting c# minor into E major (the relative major)
put(7, sfxline(7, [
  nt(P('cs', 2), 5, 5), nt(P('e', 2), 5, 5), nt(P('gs', 2), 5, 5),
  nt(P('cs', 3), 5, 6), nt(P('e', 3), 5, 6), nt(P('gs', 3), 5, 6),
  nt(P('b', 3), 5, 6), nt(P('e', 4), 5, 7), nt(P('gs', 4), 5, 7),
  nt(P('b', 4), 5, 7, 5),
]));

// 08 intro trace — sparse quiet tick under the wireframe pc
put(8, sfxline(4, [nt(P('gs', 4), 0, 1)]));

// 09 grid reveal — soft ascending organ sweep as the numbers come in
put(9, sfxline(5, [
  nt(P('cs', 2), 5, 1, 4), nt(P('e', 2), 5, 2), nt(P('gs', 2), 5, 2),
  nt(P('cs', 3), 5, 3), nt(P('e', 3), 5, 3), nt(P('gs', 3), 5, 2),
  nt(P('cs', 4), 5, 2, 5),
]));

// 10 selection full — the "no" tick.  It used to share slot 0 with the
// cursor blip, which made that one pitch even more relentless.
put(10, sfxline(7, [
  nt(P('gs', 2), 1, 3),
  nt(P('fs', 2), 1, 2),
]));

// ------------------------------------------------------------------- startup
// 11 boot — the wireframe pc assembling itself, in the voice of an old
// machine waking up.  It has to last exactly as long as the intro
// animation (28 segments x 3 frames = 84 frames = 2.8s at 30fps), so:
// 32 slots x speed 11 / 128 = 2.75s, then sfx 12 lands on the last frame.
// Three phases, one after the other because it is a single channel:
// psu/fan spin-up, rom chatter, then a beat of silence before the beep.
const BOOTSCALE = [
  P('cs', 2), P('e', 2), P('gs', 2), P('b', 2), P('cs', 3),
  P('e', 3), P('gs', 3), P('b', 3), P('cs', 4),
];
// generally climbing, but stepping over itself — a machine working down a
// checklist, not a power-up jingle.
const CHATTER = [0, 4, 1, 5, 2, 6, 3, 7, 4, 8, 5, 7, 6, 8, 7, 8, 6, 8];
const boot = [
  nt(P('cs', 1), 2, 1, 4),                          // 0     fan catches
  nt(P('cs', 1), 2, 1, 2),
  ...Array(8).fill(nt(P('cs', 1), 2, 2, 2)),         // 2-9   up to speed
  ...CHATTER.map((i) => nt(BOOTSCALE[i], 4, 2)),     // 10-27 rom chatter
];                                                   // 28-31 rest
put(11, sfxline(11, boot));

// 12 post beep — one square tone at ~1.1khz, the pc speaker saying it
// passed.  Fired the frame the wireframe finishes.
put(12, sfxline(30, [nt(P('cs', 4), 3, 5, 5)]));


// ---------------------------------------------------------------------- music
// A Moonlight-flavoured c# minor bed.  Each chord owns one 16-slot bar
// (~4s), the progression is 16 bars, two bars per music pattern, 8
// patterns a bank.  speed 32 -> 0.25s a slot -> a ~75bpm feel.
const SPD = 32;
const CLEN = 16;                   // slots per bar
const CHORDS = 16;                 // bars in the progression
const PATS = CHORDS * CLEN / 32;   // = 8 music patterns per bank

// Each chord: the bass root (low octave), the four arpeggio tones the right
// hand may use, and the pitch classes the melody may sing over it.
const CH = {
  cshm: { bass: P('cs', 1), tones: [P('gs', 2), P('cs', 3), P('e', 3), P('gs', 3)], mel: 'cs ds e fs gs a b' },
  a:    { bass: P('a', 0),  tones: [P('a', 2), P('cs', 3), P('e', 3), P('a', 3)],   mel: 'a b cs e fs' },
  fshm: { bass: P('fs', 0), tones: [P('fs', 2), P('a', 2), P('cs', 3), P('fs', 3)], mel: 'fs gs a b cs e' },
  gs7:  { bass: P('gs', 0), tones: [P('gs', 2), P('c', 3), P('ds', 3), P('fs', 3)], mel: 'gs c ds fs' },
  e:    { bass: P('e', 1),  tones: [P('e', 2), P('gs', 2), P('b', 2), P('e', 3)],   mel: 'e fs gs a b cs' },
  b:    { bass: P('b', 0),  tones: [P('fs', 2), P('b', 2), P('ds', 3), P('fs', 3)], mel: 'b cs ds e fs gs' },
};

// i - V7 - i - III | VI - III - iv - V7 | i - VI - iv - VII | III - VII - iv - V7
const PROG = [
  'cshm', 'gs7', 'cshm', 'e',
  'a',    'e',   'fshm', 'gs7',
  'cshm', 'a',   'fshm', 'b',
  'e',    'b',   'fshm', 'gs7',
];

// Right-hand figures: 16 slots each, so they line up with the bar instead
// of being sliced mid-figure (the old 6-slot figure left 4 slots over
// every bar, which is what made the ostinato stumble).  '.' is a real
// rest — the old arp sounded on 100% of slots for 64 seconds straight,
// with no gap anywhere for the ear to reset.
const FIGS = [
  '0123210123210123',   // 0 continuous arch
  '012.012.321.012.',   // 1 three-and-a-gap groove
  '0.123.210.123.21',   // 2 offbeat
  '0123..210123..10',   // 3 breathing
  '0213021320312031',   // 4 broken / spread
  '0..12..3..2..1..',   // 5 sparse, for phrase ends
];
// which figure each bar uses; never the same two bars running (checked below)
const FIGOF = [0, 1, 4, 5, 2, 0, 1, 3, 4, 2, 0, 5, 1, 4, 2, 3];

// Melody rhythms: which slots of the bar carry a note.  Rotating these
// keeps the melody off a fixed 0/4/8/12 grid.
const RHY = [
  [0, 4, 8, 12], [0, 4, 6, 12], [0, 2, 8, 10],
  [0, 6, 8, 14], [2, 4, 8, 12], [0, 4, 10, 12],
];

// Four notes a bar, all different within the bar.  Silent unless the tense
// bank is playing.
const M = (s) => s.split(' ').map((w) => P(w.slice(0, -1), +w.slice(-1)));
const MEL = [
  M('e4 cs4 b3 gs3'),   //  0 c#m
  M('ds4 c4 gs3 fs3'),  //  1 G#7
  M('e3 gs3 cs4 b3'),   //  2 c#m
  M('gs3 b3 e4 cs4'),   //  3 E
  M('a3 cs4 e4 b3'),    //  4 A
  M('gs3 b3 cs4 e4'),   //  5 E
  M('cs4 b3 a3 fs3'),   //  6 f#m
  M('gs3 c4 ds4 fs3'),  //  7 G#7
  M('e3 gs3 b3 cs4'),   //  8 c#m
  M('e4 cs4 a3 b3'),    //  9 A
  M('fs3 a3 cs4 e4'),   // 10 f#m
  M('ds4 cs4 b3 fs3'),  // 11 B
  M('b3 gs3 cs4 e4'),   // 12 E
  M('fs3 gs3 b3 ds4'),  // 13 B
  M('a3 cs4 b3 fs3'),   // 14 f#m
  M('gs3 fs3 c4 ds4'),  // 15 G#7
];

// ---- static checks on the tables ----
if (PROG.length !== CHORDS || MEL.length !== CHORDS || FIGOF.length !== CHORDS) {
  throw new Error('progression length mismatch');
}
for (const f of FIGS) if (f.length !== CLEN) throw new Error('figure is not 16 slots: ' + f);
for (let c = 0; c < CHORDS; c++) {
  const n = (c + 1) % CHORDS;
  if (PROG[c] === PROG[n]) throw new Error(`chord ${c} repeats into ${n}`);
  if (FIGOF[c] === FIGOF[n]) throw new Error(`figure ${c} repeats into ${n}`);
  const ch = CH[PROG[c]];
  if (!ch) throw new Error('unknown chord ' + PROG[c]);
  const okmel = new Set(ch.mel.split(' ').map((x) => NAME[x]));
  if (MEL[c].length !== 4) throw new Error(`bar ${c} melody is not 4 notes`);
  if (new Set(MEL[c]).size !== 4) throw new Error(`bar ${c} repeats a note inside the bar`);
  for (const m of MEL[c]) {
    if (!okmel.has(m % 12)) throw new Error(`melody ${pname(m)} does not fit bar ${c} (${PROG[c]})`);
  }
  if (MEL[c][3] === MEL[n][0]) throw new Error(`melody repeats across bar ${c}/${n}`);
}
if (new Set(MEL.map((b) => b.join())).size !== CHORDS) throw new Error('two bars share a melody');

// ---- render ----
const bassP = [], arpP = [], melP = [];   // pitch per slot, null = rest
for (let c = 0; c < CHORDS; c++) {
  const ch = CH[PROG[c]];
  const fig = FIGS[FIGOF[c]];
  const rhy = RHY[c % RHY.length];
  for (let j = 0; j < CLEN; j++) {
    // bass: octave pulse on the chord change and halfway through, plus a
    // fifth pushing into the next chord on every other bar.
    bassP.push(j === 0 ? ch.bass : j === 8 ? ch.bass + 12 : (j === 12 && c % 2 === 1) ? ch.bass + 7 : null);
    const f = fig[j];
    arpP.push(f === '.' ? null : ch.tones[+f]);
    const k = rhy.indexOf(j);
    melP.push(k < 0 ? null : MEL[c][k]);
  }
}

// ---- vertical check: nothing may sound a semitone or major 7th apart in
// the same slot.  A tritone is allowed only inside G#7, where it is the
// chord's own dominant colour rather than a stray note.
for (let i = 0; i < CHORDS * CLEN; i++) {
  const ch = PROG[Math.floor(i / CLEN)];
  const v = [['mel', melP[i]], ['arp', arpP[i]], ['bass', bassP[i]]].filter((x) => x[1] != null);
  for (let x = 0; x < v.length; x++) {
    for (let y = x + 1; y < v.length; y++) {
      const iv = Math.abs(v[x][1] - v[y][1]) % 12;
      const bad = iv === 1 || iv === 11 || (iv === 6 && ch !== 'gs7');
      if (bad) {
        throw new Error(`bar ${Math.floor(i / CLEN)} slot ${i % CLEN}: ${v[x][0]} ${pname(v[x][1])} ` +
          `against ${v[y][0]} ${pname(v[y][1])} (${iv} semitones)`);
      }
    }
  }
}

for (let p = 0; p < PATS; p++) {
  const bass = [], arp = [], mel = [];
  for (let i = 0; i < 32; i++) {
    const s = p * 32 + i;
    bass.push(bassP[s] != null ? nt(bassP[s], 0, 2, 5) : REST);
    arp.push(arpP[s] != null ? nt(arpP[s], 0, 2, 0) : REST);
    mel.push(melP[s] != null ? nt(melP[s], 0, 3, 5) : REST);
  }
  put(16 + p, sfxline(SPD, bass));
  put(24 + p, sfxline(SPD, arp));
  put(32 + p, sfxline(SPD, mel));
}

// ------------------------------------------------------------------ assemble
const top = [];
for (let i = 0; i < SFX.length; i++) top.push(SFX[i] || sfxline(1, []));

// music patterns: 0-7 calm bank, 8-15 tense bank (adds the melody voice).
// flag bit 0 = loop start, bit 1 = loop end.  44 on a channel = unused.
const music = [];
const bank = (mel) => {
  for (let p = 0; p < PATS; p++) {
    const flag = p === 0 ? '01' : p === PATS - 1 ? '02' : '00';
    const ch2 = mel ? h2(32 + p) : '44';
    music.push(`${flag} ${h2(16 + p)}${h2(24 + p)}${ch2}44`);
  }
};
bank(false);
bank(true);

for (const l of top) if (l.length !== 168) throw new Error('bad sfx width: ' + l.length);
for (const l of music) if (l.length !== 11) throw new Error('bad music width: ' + l.length);
if (top.length > 64) throw new Error('more than 64 sfx: ' + top.length);
if (music.length > 64) throw new Error('more than 64 music patterns');

const cart = fs.readFileSync('game.p8', 'utf8');
const i = cart.indexOf('__sfx__');
if (i < 0) throw new Error('no __sfx__ marker in game.p8');
const out = cart.slice(0, i) +
  '__sfx__\n' + top.join('\n') + '\n' +
  '__music__\n' + music.join('\n') + '\n';
fs.writeFileSync('game.p8', out);

const sounding = arpP.filter((x) => x != null).length;
console.log(`wrote ${top.length} sfx, ${music.length} music patterns ` +
  `(${(PATS * 32 * SPD / 128).toFixed(1)}s loop, arp sounds on ` +
  `${Math.round(sounding / arpP.length * 100)}% of slots)`);
