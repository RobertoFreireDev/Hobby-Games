// audiogen.js — generates the __sfx__ and __music__ sections of game.p8
// and splices them into the cart. See snake-pico8-guide.md §8.
//
//   node audiogen.js
//
// Layout follows §8.9: 0-5 step (one per pentatonic degree), 6 eat,
// 7 door, 8 bump, 9 look forward, 10 die, 11 win, 12-15 bass,
// 16-19 pad, 20-25 melody, 26 look back, 27 deny.

const fs = require('fs');
const CART = 'game.p8';

// ---------- note helpers ----------
// waveforms
const TRI = 0, TSAW = 1, SQR = 3, PULSE = 4, ORGAN = 5, NOISE = 6, PHASER = 7;
// effects
const NONE = 0, SLIDE = 1, VIB = 2, DROP = 3, FADEIN = 4, FADEOUT = 5, ARP = 6;

const REST = null;
const n = (pitch, wave, vol, fx = NONE) => ({ pitch, wave, vol, fx });

// A held note: first slot attacks, the rest slide into it so PICO-8 does not
// re-trigger the envelope 8 times a bar (§8.1 — nothing here should pulse).
function hold(pitch, wave, vol, len, fx = NONE) {
  const out = [];
  for (let i = 0; i < len; i++) out.push(n(pitch, wave, vol, i === 0 ? fx : SLIDE));
  return out;
}
const rest = len => Array(len).fill(REST);
const seq = (...parts) => [].concat(...parts);

function sfxLine(speed, notes, { mode = 1, loopStart = 0, loopEnd = 0 } = {}) {
  if (notes.length > 32) throw new Error('sfx has ' + notes.length + ' notes');
  const h = (v, w) => v.toString(16).padStart(w, '0');
  let s = h(mode, 2) + h(speed, 2) + h(loopStart, 2) + h(loopEnd, 2);
  for (let i = 0; i < 32; i++) {
    const nt = notes[i];
    if (!nt) { s += '00000'; continue; }
    if (nt.pitch < 0 || nt.pitch > 63) throw new Error('pitch out of range: ' + nt.pitch);
    s += h(nt.pitch, 2) + h(nt.wave, 1) + h(nt.vol, 1) + h(nt.fx, 1);
  }
  if (s.length !== 168) throw new Error('sfx line is ' + s.length + ' chars');
  return s;
}

// ---------- pitches ----------
// pitch 0 = C-0. C major pentatonic in every octave we use.
const C1=12, D1=14, E1=16, F1=17, G1=19, A1=21;
const C2=24, D2=26, E2=28, F2=29, G2=31, A2=33, B2=35;
const C3=36, D3=38, E3=40, G3=43, A3=45;
const C4=48, D4=50, E4=52, G4=55, A4=57;
const C5=60, D5=62;

const sfx = [];
const put = (slot, line) => { sfx[slot] = line; };

// ---------- 0-5: step, one per row of the board (§8.7) ----------
// Bottom row is the root, top row the octave: moving up the grid plays up the
// scale. Quiet and plucked so a fast player does not stack them into mush.
const STEP = [C3, D3, E3, G3, A3, C4];
STEP.forEach((p, i) => put(i, sfxLine(9, [
  n(p, TRI, 3, FADEOUT),
  n(p, TRI, 2, FADEOUT),
  n(p, TRI, 1, FADEOUT),
])));

// ---------- 6-11, 26-27: one-shots ----------
put(6, sfxLine(7, [                        // eat: rising figure
  n(C4, PULSE, 4), n(E4, PULSE, 4), n(G4, PULSE, 4), n(C5, PULSE, 4, FADEOUT),
]));
// door: phaser sweep. Pentatonic, not a chromatic ramp — this one fires
// mid-move over whatever the bed is holding, so it has to consonate.
put(7, sfxLine(6, [
  n(C3, PHASER, 3),
  ...[E3, G3, C4, E4, G4, C5].map(p => n(p, PHASER, 3, SLIDE)),
  n(E4, PHASER, 2, FADEOUT),
]));
put(8, sfxLine(8, [                        // bump: soft thud, almost inaudible
  n(C1, NOISE, 1, FADEOUT), n(C1, NOISE, 1, FADEOUT),
]));
put(9, sfxLine(6, [n(A3, PULSE, 1, FADEOUT)]));   // look forward
put(26, sfxLine(6, [n(G3, PULSE, 1, FADEOUT)]));  // look back: a tone lower
// deny: the press was heard and refused (a bite the player did not need to
// take). It must not sound like the bump — that one is a soft noise thud for
// "nothing there", while this one is an error, so it is pitched and falls.
// A-C-E descending: an Am triad, consonant with the Cmaj7/Am7 vamp it fires
// over, loud enough to be read as a refusal but still short.
put(27, sfxLine(7, [
  n(E3, SQR, 3), n(C3, SQR, 3, FADEOUT), n(A2, SQR, 2, FADEOUT),
]));
put(10, sfxLine(14, [                      // die: triangle, dropping
  n(G3, TRI, 4, DROP), n(D3, TRI, 4, DROP), n(A2, TRI, 3, DROP),
  n(E2, TRI, 3, DROP), n(C2, TRI, 2, FADEOUT),
]));
put(11, sfxLine(13, [                      // win: pentatonic run up
  n(C3, PULSE, 5), n(D3, PULSE, 5), n(E3, PULSE, 5), n(G3, PULSE, 5),
  n(A3, PULSE, 5), n(C4, PULSE, 5), n(D4, PULSE, 5), n(E4, PULSE, 5),
  n(G4, PULSE, 5), n(A4, PULSE, 5),
  ...hold(C5, PULSE, 5, 6),
]));

// ---------- 12-25: the bed (§8.6) ----------
// speed 32 = 60 BPM, 32 notes = 2 bars. Eight patterns => ~68 s before repeat.
const BED = 32;

// bass: root for a bar, then a fifth, slid into so it never thumps
const bass = (root, other) => sfxLine(BED, seq(hold(root, TRI, 3, 16), hold(other, TRI, 3, 16)));
put(12, bass(C2, G1));   // Cmaj7
put(13, bass(F1, C2));   // Fmaj7
put(14, bass(A1, E1));   // Am7
put(15, bass(G1, D1));   // G7sus4

// pad: organ walking the chord tones, 8 slots each — reads as a sustained wash
const pad = (a, b, c, d) => sfxLine(BED, seq(
  hold(a, ORGAN, 2, 8, FADEIN), hold(b, ORGAN, 2, 8),
  hold(c, ORGAN, 2, 8), hold(d, ORGAN, 2, 8)));
put(16, pad(G2, B2, E2, G2));   // Cmaj7
put(17, pad(A2, C3, F2, A2));   // Fmaj7
put(18, pad(E2, G2, A2, G2));   // Am7
put(19, pad(G2, C3, D3, C3));   // G7sus4

// melody: triangle ocarina, pentatonic so it cannot clash with the vamp.
// Each phrase leaves its last bar empty — that is the breath.
const mel = notes => sfxLine(BED, notes);
// a bird figure: one arpeggiated group, pulse wave, sits inside a melody rest
const bird = () => [n(A4, PULSE, 2, ARP), n(C5, PULSE, 2, ARP),
                    n(D5, PULSE, 2, ARP), n(C5, PULSE, 2, ARP)];

put(20, mel(seq(hold(E4, TRI, 3, 8), hold(G4, TRI, 3, 4), hold(A4, TRI, 3, 4),
                hold(G4, TRI, 3, 8), rest(8))));
put(21, mel(seq(hold(C5, TRI, 3, 6), rest(2), hold(A4, TRI, 3, 4),
                hold(G4, TRI, 3, 4), hold(E4, TRI, 3, 8), rest(8))));
put(22, mel(seq(hold(A4, TRI, 3, 8), hold(G4, TRI, 3, 4), hold(E4, TRI, 3, 4),
                hold(D4, TRI, 3, 8), rest(4), bird())));
put(23, mel(seq(hold(A4, TRI, 3, 8), hold(C5, TRI, 3, 4), hold(A4, TRI, 3, 4),
                hold(G4, TRI, 3, 8), rest(8))));
put(24, mel(seq(hold(E4, TRI, 3, 8), hold(D4, TRI, 3, 4), hold(C4, TRI, 3, 4),
                hold(D4, TRI, 3, 8), rest(8))));
put(25, mel(seq(hold(A4, TRI, 3, 8), hold(G4, TRI, 3, 8), hold(E4, TRI, 3, 8),
                rest(4), bird())));

// ---------- music patterns ----------
const OFF = [0x41, 0x42, 0x43, 0x44];
function pattern(flags, ch) {
  const b = ch.map((v, i) => (v === null ? OFF[i] : v).toString(16).padStart(2, '0'));
  return flags.toString(16).padStart(2, '0') + ' ' + b.join('');
}
const LOOP_START = 1, LOOP_END = 2;
const music = [
  pattern(LOOP_START, [12, 16, 20, null]),  // Cmaj7
  pattern(0,          [12, 16, 21, null]),  // Cmaj7
  pattern(0,          [13, 17, 22, null]),  // Fmaj7
  pattern(0,          [13, 17, null, null]),// Fmaj7 — melody rests
  pattern(0,          [14, 18, 23, null]),  // Am7
  pattern(0,          [14, 18, 24, null]),  // Am7
  pattern(0,          [13, 17, 25, null]),  // Fmaj7
  pattern(LOOP_END,   [15, 19, null, null]),// G7sus4 — melody rests
];

// ---------- splice ----------
for (let i = 0; i <= 27; i++) if (!sfx[i]) sfx[i] = sfxLine(1, []);
const cart = fs.readFileSync(CART, 'utf8').replace(/\r\n/g, '\n');
const head = cart.slice(0, cart.indexOf('__sfx__'));
if (!head) throw new Error('no __sfx__ marker in ' + CART);
const out = head + '__sfx__\n' + sfx.join('\n') + '\n__music__\n' + music.join('\n') + '\n';
fs.writeFileSync(CART, out);
console.log('wrote ' + sfx.length + ' sfx, ' + music.length + ' patterns');
