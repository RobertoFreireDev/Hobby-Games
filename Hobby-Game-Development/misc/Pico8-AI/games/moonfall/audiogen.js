// audiogen.js -- MOONFALL sound effects and music
//
// Exports buildSfx()/buildMusic() for build.js; run directly for a readable
// dump of every slot (tempo and pattern order cannot be checked at runtime
// under `pico8 -x`, so the dump is how those get reviewed).
//
// The whole soundtrack is ONE motif in five states (§10.1). Same key, same
// contour; what changes is the third, the bass, and the tempo. That is what
// makes the clock audible -- the player hears the day rotting rather than
// hearing four unrelated tracks.

'use strict';

const hx = (n, w) => n.toString(16).padStart(w, '0');

// waveforms
const TRI = 0, TSAW = 1, SAW = 2, SQR = 3, PUL = 4, ORG = 5, NOI = 6, PHA = 7;
// effects
const NONE = 0, SLIDE = 1, VIB = 2, DROP = 3, FADEIN = 4, FADEOUT = 5, ARP = 6;

const note = (p, w, v, e) => ({ p, w, v, e: e || 0 });
const REST = null;

function sfxLine(speed, notes, loopStart, loopEnd) {
  if (notes.length > 32) throw new Error('sfx has ' + notes.length + ' notes');
  let s = '01' + hx(speed, 2) + hx(loopStart || 0, 2) + hx(loopEnd || 0, 2);
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    s += n ? hx(n.p, 2) + hx(n.w, 1) + hx(n.v, 1) + hx(n.e, 1) : '00000';
  }
  if (s.length !== 168) throw new Error('sfx line width ' + s.length);
  return s;
}

// ---------------------------------------------------------------- the motif

// scale degrees, then the same shape inverted for the last state
const MOTIF = [0, 4, 7, 4, 5, 4, 2, 0];
const INVERTED = [0, -4, -7, -4, -5, -4, -2, 0];

// major / natural-minor semitone offsets for a scale degree
function degree(d, minor) {
  const maj = [0, 2, 4, 5, 7, 9, 11];
  const min = [0, 2, 3, 5, 7, 8, 10];
  const t = minor ? min : maj;
  const oct = Math.floor(d / 7), i = ((d % 7) + 7) % 7;
  return t[i] + 12 * oct;
}

const ROOT = 33;   // a-2

// One 16-step bar of arpeggio over a held bass, in whichever state applies.
function bar(opts) {
  const { minor, shape, wave, vol, thin, offset } = opts;
  const mel = [];
  for (let i = 0; i < 16; i++) {
    const d = shape[i % shape.length];
    if (thin && i % 2 === 1) { mel.push(REST); continue; }
    mel.push(note(ROOT + 12 + degree(d, minor) + (offset || 0), wave, vol));
  }
  return mel;
}

function bassLine(opts) {
  const { minor, wave, vol, root, tritone, pulse } = opts;
  const out = [];
  for (let i = 0; i < 16; i++) {
    if (pulse) {
      out.push(i % 2 === 0
        ? note(ROOT - 12 + (tritone && i >= 8 ? 6 : 0) + root, wave, vol)
        : REST);
    } else {
      out.push(i % 8 === 0
        ? note(ROOT - 12 + (tritone && i >= 8 ? 6 : 0) + root, wave, vol, FADEOUT)
        : REST);
    }
  }
  if (minor) { /* the third lives in the melody, not the bass */ }
  return out;
}

// state -> { speed, mel opts, bass opts }
const STATES = {
  morning:   { speed: 18, mel: { minor: false, shape: MOTIF, wave: ORG, vol: 4 },
               bass: { wave: TRI, vol: 3, root: 0 } },
  afternoon: { speed: 18, mel: { minor: true, shape: MOTIF, wave: ORG, vol: 4 },
               bass: { wave: TRI, vol: 4, root: 0, pulse: true } },
  dusk:      { speed: 20, mel: { minor: true, shape: MOTIF, wave: TRI, vol: 3, thin: true },
               bass: { wave: SAW, vol: 4, root: 0, tritone: true, pulse: true } },
  nightfall: { speed: 14, mel: { minor: true, shape: INVERTED, wave: PHA, vol: 5 },
               bass: { wave: SAW, vol: 5, root: 0, tritone: true, pulse: true } },
  intro:     { speed: 22, mel: { minor: true, shape: MOTIF, wave: ORG, vol: 4 },
               bass: { wave: TRI, vol: 3, root: 0 } },
};

// ---------------------------------------------------------------- assembly

function build() {
  const sfx = new Array(64).fill(null);

  // --- game sounds (§10.2). Every input makes a sound.
  sfx[0] = sfxLine(4, [note(24, NOI, 2, FADEOUT), note(20, NOI, 1, FADEOUT)]);
  sfx[1] = sfxLine(6, [note(14, NOI, 3, DROP), note(10, NOI, 2, FADEOUT)]);
  sfx[2] = sfxLine(7, [note(33, ORG, 3), note(40, ORG, 4), note(45, ORG, 3, FADEOUT)]);
  sfx[3] = sfxLine(7, [note(45, ORG, 3), note(38, ORG, 3), note(31, ORG, 2, FADEOUT)]);

  // 4-11: one fixed base note each -- this is what a villager's "voice" is
  const VOICE = [46, 43, 34, 45, 30, 32, 44, 38];
  const VWAVE = [ORG, TRI, TRI, PUL, SQR, TRI, ORG, PUL];
  VOICE.forEach((p, i) => {
    sfx[4 + i] = sfxLine(3, [note(p, VWAVE[i], 2), note(p - 2, VWAVE[i], 1, FADEOUT)]);
  });

  sfx[12] = sfxLine(5, [note(30, NOI, 2), note(38, NOI, 2, FADEOUT)]);
  sfx[13] = sfxLine(4, [note(40, SQR, 2, FADEOUT)]);
  sfx[14] = sfxLine(5, [note(40, ORG, 4), note(47, ORG, 4, FADEOUT)]);
  sfx[15] = sfxLine(5, [note(40, ORG, 3), note(33, ORG, 3, FADEOUT)]);
  sfx[16] = sfxLine(14, [note(45, TRI, 4), REST, note(38, TRI, 3, FADEOUT)]);
  sfx[17] = sfxLine(4, [note(45, TRI, 3), note(50, TRI, 3, FADEOUT)]);
  sfx[18] = sfxLine(9, [note(37, SAW, 4), note(38, SAW, 4, FADEOUT)]);   // a semitone apart
  sfx[19] = sfxLine(11, [note(26, SAW, 5, VIB), note(26, SAW, 4, FADEOUT)]);

  // the howl: one long slide down, the sound the whole cart is named for
  sfx[20] = sfxLine(16, [
    note(40, ORG, 5, SLIDE), note(45, ORG, 6, VIB), note(45, ORG, 6, VIB),
    note(43, ORG, 5, SLIDE), note(38, ORG, 5, VIB), note(33, ORG, 4, FADEOUT),
  ]);
  sfx[21] = sfxLine(8, [
    note(30, NOI, 5, DROP), note(26, SAW, 5, DROP), note(20, SAW, 5, DROP),
    note(14, NOI, 4, FADEOUT),
  ]);
  // the motif resolved at last, major
  sfx[22] = sfxLine(10, [
    note(45, ORG, 5), note(49, ORG, 5), note(52, ORG, 5), note(57, ORG, 6, FADEOUT),
  ]);
  // and the motif collapsing, with no resolution
  sfx[23] = sfxLine(12, [
    note(45, PHA, 5), note(44, PHA, 5), note(39, PHA, 4), note(32, PHA, 4, FADEOUT),
  ]);

  // --- music beds. Two patterns per state, so each state loops on itself.
  const layout = [
    ['morning', 0, 24], ['afternoon', 4, 28], ['dusk', 8, 32],
    ['nightfall', 12, 36], ['intro', 16, 40],
  ];
  const music = new Array(24).fill('00 41424344');

  for (const [name, pat, slot] of layout) {
    const st = STATES[name];
    for (let half = 0; half < 2; half++) {
      const mel = bar({ ...st.mel, offset: half ? -5 : 0 });   // answer a fifth below
      const bass = bassLine({ ...st.bass, minor: st.mel.minor, root: half ? -5 : 0 });
      sfx[slot + half * 2] = sfxLine(st.speed, mel);
      sfx[slot + half * 2 + 1] = sfxLine(st.speed, bass);
      const flag = half === 0 ? '01' : '02';                   // loop start / loop end
      music[pat + half] = flag + ' ' + hx(slot + half * 2, 2) + hx(slot + half * 2 + 1, 2) + '4344';
    }
  }
  // victory and defeat play once and stop; both point at the stings above
  music[20] = '04 16424344';   // sfx 22
  music[22] = '04 17424344';   // sfx 23

  return { sfx, music };
}

function buildSfx() {
  const { sfx } = build();
  // trailing empty slots are simply left out of the section
  let last = 63;
  while (last >= 0 && !sfx[last]) last--;
  const empty = sfxLine(1, []);
  return sfx.slice(0, last + 1).map(l => l || empty).join('\n');
}

function buildMusic() {
  const { music } = build();
  return music.join('\n');
}

module.exports = { buildSfx, buildMusic };

if (require.main === module) {
  const { sfx, music } = build();
  const WAVE = ['tri', 'tsaw', 'saw', 'sqr', 'pul', 'org', 'noi', 'pha'];
  const NAMES = ['step', 'bump', 'talk open', 'talk close',
    ...Array.from({ length: 8 }, (_, i) => 'voice ' + (i + 1)),
    'page turn', 'menu move', 'menu ok', 'menu back', 'hour chime', 'clue logged',
    'contradiction', 'accuse', 'howl', 'transform', 'win sting', 'lose sting'];
  console.log('--- sfx ---');
  sfx.forEach((l, i) => {
    if (!l) return;
    const speed = parseInt(l.slice(2, 4), 16);
    const ns = [];
    for (let k = 0; k < 32; k++) {
      const c = l.slice(8 + k * 5, 13 + k * 5);
      if (c === '00000') continue;
      ns.push(`${parseInt(c.slice(0, 2), 16)}/${WAVE[parseInt(c[2], 16)]}/v${c[3]}/e${c[4]}`);
    }
    console.log(`${String(i).padStart(2)} ${(NAMES[i] || 'music bed').padEnd(14)} ` +
      `spd ${String(speed).padStart(2)}  ${ns.slice(0, 6).join(' ')}${ns.length > 6 ? ' ...' : ''}`);
  });
  console.log('\n--- music ---');
  music.forEach((l, i) => {
    if (l === '00 41424344') return;
    console.log(String(i).padStart(2) + ' ' + l);
  });
}
