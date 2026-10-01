// gen-sfx.js — writes the __sfx__ and __music__ sections of games/gridlock/game.p8.
// sfx line: [mode:2][speed:2][loopstart:2][loopend:2] + 32 notes x [pitch:2][wave:1][vol:1][fx:1]
// music line: [flags:2] space [ch0:2][ch1:2][ch2:2][ch3:2]
//
// Slots 0-7 are gameplay sounds and always play on channel 3.
// Slots 8-17 are the balloon-party bed, which owns channels 0-2.
//
// run: node games/gridlock/gen-sfx.js   (from anywhere)
const fs = require('fs');
const path = require('path');
const CART = path.join(__dirname, 'game.p8');

const h1 = n => n.toString(16);
const h2 = n => n.toString(16).padStart(2, '0');

// note: [pitch, waveform, volume, effect]
function line(speed, notes) {
  let s = '00' + h2(speed) + '0000';
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    s += n ? h2(n[0]) + h1(n[1]) + h1(n[2]) + h1(n[3] || 0) : '00000';
  }
  if (s.length !== 168) throw new Error('sfx line width ' + s.length);
  return s;
}

const W = { tri: 0, tsaw: 1, saw: 2, sqr: 3, pul: 4, org: 5, noi: 6, pha: 7 };
const sfx = [];

// ---------------- gameplay sounds ----------------

// 0 — piece slides: short low noise thunk. plays dozens of times a level, stays quiet.
sfx[0] = line(4, [[0x14, W.noi, 3, 5], [0x0a, W.noi, 2, 5]]);
// 1 — grab: rising two-note blip
sfx[1] = line(5, [[0x20, W.org, 4, 0], [0x27, W.org, 4, 5]]);
// 2 — drop: falling two-note blip, mirror of grab
sfx[2] = line(5, [[0x27, W.org, 4, 0], [0x20, W.org, 4, 5]]);
// 3 — rejected input: low square buzz
sfx[3] = line(7, [[0x09, W.sqr, 3, 0], [0x06, W.sqr, 3, 5]]);
// 4 — cursor step: very quiet high tick
sfx[4] = line(3, [[0x34, W.saw, 1, 5]]);
// 5 — exit: five-note rising arpeggio
sfx[5] = line(6, [
  [0x18, W.org, 5, 0], [0x1c, W.org, 5, 0], [0x1f, W.org, 5, 0],
  [0x24, W.org, 5, 0], [0x28, W.org, 6, 5],
]);
// 6 — detonation: a hard noise hit that tears downward as the board blows apart
sfx[6] = line(6, [
  [0x38, W.noi, 7, 0], [0x30, W.noi, 7, 3], [0x26, W.noi, 6, 3], [0x1c, W.noi, 6, 3],
  [0x14, W.noi, 5, 3], [0x0e, W.noi, 5, 5], [0x08, W.noi, 4, 5], [0x04, W.noi, 3, 5],
]);
// 7 — out of moves: sagging minor fall, played over the blast
sfx[7] = line(11, [
  [0x1e, W.sqr, 5, 0], [0x1b, W.sqr, 5, 0], [0x17, W.sqr, 4, 0], [0x12, W.sqr, 4, 5],
]);

// ---------------- balloon party bed ----------------
// C major, 150bpm, sixteenth-note grid. one sfx = 32 sixteenths = two bars.
// four patterns: C|G  Am|F  C|G  F|G

const P = { c2: 24, d2: 26, e2: 28, f2: 29, g2: 31, a2: 33,
            g3: 43, a3: 45, b3: 47,
            c4: 48, d4: 50, e4: 52, f4: 53, g4: 55, a4: 57, b4: 59,
            c5: 60, d5: 62, e5: 64, f5: 65, g5: 67 };

// bass: eighth notes bouncing root / octave, with a fifth before the bar turns over
function bass(bars) {
  const out = [];
  for (const r of bars) {
    const step = [r, r + 12, r, r + 12, r, r + 12, r + 7, r + 12];
    for (const p of step) { out.push([p, W.tsaw, 4, 5]); out.push(null); }
  }
  return line(12, out);
}

// melody: one entry per sixteenth, null = rest. held feel comes from fade-out.
function mel(slots) {
  return line(12, slots.map(p => (p ? [p, W.pul, 5, 5] : null)));
}

const K = [0x06, W.noi, 5, 3];   // kick
const S = [0x1e, W.noi, 4, 5];   // snare
const H = [0x30, W.noi, 2, 5];   // hat
function drums(fill) {
  const bar = [K, null, H, null, S, null, H, null, K, null, H, null, S, null, H, null];
  const out = bar.concat(fill ? [K, null, H, null, S, null, H, null, K, null, K, null, S, S, S, S]
                              : bar);
  return line(12, out);
}

const m = P;
// bass, one root per bar
sfx[8]  = bass([m.c2, m.g2]);
sfx[9]  = bass([m.a2, m.f2]);
sfx[10] = bass([m.c2, m.g2]);
sfx[11] = bass([m.f2, m.g2]);

// melody, sixteenth grid: notes on the offbeats give it the balloon-bounce lift
sfx[12] = mel([m.e4, 0, m.g4, 0, m.c5, 0, 0, m.g4, m.e4, 0, m.g4, 0, m.a4, 0, m.g4, 0,
               m.d4, 0, m.g4, 0, m.b4, 0, 0, m.g4, m.d5, 0, m.b4, 0, m.g4, 0, m.d4, 0]);
sfx[13] = mel([m.a4, 0, m.c5, 0, m.e5, 0, 0, m.c5, m.a4, 0, m.c5, 0, m.b4, 0, m.a4, 0,
               m.f4, 0, m.a4, 0, m.c5, 0, 0, m.a4, m.f4, 0, m.a4, 0, m.g4, 0, m.f4, 0]);
sfx[14] = mel([m.c5, 0, m.e5, 0, m.g5, 0, m.e5, 0, m.c5, 0, m.g4, 0, m.e4, 0, m.g4, 0,
               m.d5, 0, m.b4, 0, m.g4, 0, m.b4, 0, m.d5, 0, m.g5, 0, 0, 0, m.d5, 0]);
sfx[15] = mel([m.f5, 0, m.e5, 0, m.c5, 0, m.a4, 0, m.f4, 0, m.a4, 0, m.c5, 0, m.f5, 0,
               m.g5, 0, m.d5, 0, m.b4, 0, m.g4, 0, m.d5, 0, m.g5, 0, m.b4, m.d5, m.g5, 0]);

sfx[16] = drums(false);
sfx[17] = drums(true);

// ---------------- patterns ----------------
// channel 3 is left off so gameplay sfx always have a free voice.
// bass 8-11, melody 12-15, drums 16-17; channel 3 stays off (41).
const pat = (b, mch, d, flag) => flag + ' ' + h2(b) + h2(mch) + h2(d) + '41';
const musicLines = [
  pat(8, 12, 16, '01'),
  pat(9, 13, 16, '00'),
  pat(10, 14, 16, '00'),
  pat(11, 15, 17, '02'),
];

for (const s of sfx) if (s && s.length !== 168) throw new Error('bad sfx width');
for (const l of musicLines) if (!/^[0-9a-f]{2} [0-9a-f]{8}$/.test(l)) throw new Error('bad music line ' + l);

let cart = fs.readFileSync(CART, 'utf8');
// assert the section was found rather than that the file changed, so
// regenerating identical audio stays a no-op instead of an error
function swap(text, re, body) {
  if (!re.test(text)) throw new Error('section not found: ' + re);
  return text.replace(re, body);
}
cart = swap(cart, /__sfx__\n(?:[0-9a-f]*\n)*/, '__sfx__\n' + sfx.map(s => s || line(1, [])).join('\n') + '\n');
cart = swap(cart, /__music__\n(?:[0-9a-f]{2} [0-9a-f]{8}\n)*/, '__music__\n' + musicLines.join('\n') + '\n');
fs.writeFileSync(CART, cart);
console.log('wrote ' + sfx.length + ' sfx lines (168 chars each) and ' + musicLines.length + ' music patterns');
