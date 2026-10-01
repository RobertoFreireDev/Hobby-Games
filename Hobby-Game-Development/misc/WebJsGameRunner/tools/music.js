/* Offline renderer for the music tracks. Dev tool only — nothing here ships or
   runs inside the game; it just writes the wav files in assets/music/.

     node tools/music.js            write every variation
     node tools/music.js --check    also re-render the base theme next to the
                                    original so the two can be compared

   All tracks are one 8.000 s loop over the same grid — 120 BPM, 4/4, A natural
   minor, chords Am Em G Em | Am Dm F Em->G, one bar per second. Same length,
   same tempo, same harmony at every instant, so the engine can swap the buffer
   mid-loop (api.music with sync) and land on the beat, in key, every time.
   The variations are arrangements of the one tune, not different songs:

     theme_calm    half-time bass, melody thinned to the downbeats, soft pad
     theme         (the original) driving 8th bass + pluck melody
     theme_drive   theme + a running 8th arpeggio, melody rests filled in
     theme_rush    16th bass, melody doubled a third up, 16th arpeggio

   Voices keep one free-running phase accumulator each instead of resetting per
   note, so two tracks playing the same pitch at the same instant produce the
   same samples and a crossfade between them cannot comb-filter. */

var fs = require("fs");
var path = require("path");

var RATE = 22050;                  // matches the original theme.wav
var OS = 4;                        // oversample, decimated back down at the end
var SR = RATE * OS;
var DUR = 8;                       // seconds — one full loop
var STEP = 0.125;                  // 8th note
var OUT = path.join(__dirname, "..", "assets", "music");

/* ------------------------------------------------------------------ score -- */

/* root of each 1-second bar (bar 7 walks E -> G under the turnaround) */
var BARS = [45, 40, 43, 40, 45, 38, 41, 40];        // A2 E2 G2 E2 A2 D2 F2 E2

/* the melody, one slot per 8th, null = rest. 32 slots of 0.25 s. */
var MEL = [
  81, 84, 88, 84,   86, 84, 81, null,
  79, 84, 88, 91,   88, 84, 79, null,
  81, 84, 88, 93,   91, 88, 84, null,
  77, 81, 84, 88,   86, 84, 81, 79
];

/* chord tones for the arpeggio, low enough to sit under the melody */
var CHORD = [
  [69, 72, 76],   // Am
  [64, 67, 71],   // Em
  [67, 71, 74],   // G
  [64, 67, 71],   // Em
  [69, 72, 76],   // Am
  [62, 65, 69],   // Dm
  [65, 69, 72],   // F
  [64, 67, 71]    // Em (second half swaps to G below)
];

var SCALE = [9, 11, 0, 2, 4, 5, 7];                 // A natural minor pitch classes

/* the driving 8th bass: root root +2 root, twice a bar; the last bar walks up */
function bassLine() {
  var s = [], b, r;
  for (b = 0; b < 8; b++) {
    if (b === 7) { s.push(40, 40, 40, 40, 43, 43, 45, 45); continue; }   // walk-up turnaround
    r = BARS[b];
    s.push(r, r, r + 2, r, r, r, r + 2, r);
  }
  return s;
}

/* move a note up two scale degrees, folded down an octave when it gets shrill */
function thirdUp(m) {
  var pc = ((m % 12) + 12) % 12, i = SCALE.indexOf(pc);
  if (i < 0) return m + 3;
  var j = i + 2, oct = Math.floor(j / 7);
  var out = m + (SCALE[j % 7] - pc) + 12 * oct;
  while (out <= m) out += 12;
  return out > 91 ? out - 12 : out;
}

/* --------------------------------------------------------------- synthesis -- */

function hz(m) { return 440 * Math.pow(2, (m - 69) / 12); }

function note(t, dur, midi, amp, wave, duty, env) {
  return { t: t, dur: dur, midi: midi, amp: amp, wave: wave, duty: duty, env: env };
}

/* The triangle starts its cycle at +1 to match the phase theme.wav was rendered
   with — get this backwards and the shared bass line cancels itself out while
   two tracks crossfade instead of adding. */
function shape(e, ph) {
  var p = ph - Math.floor(ph);
  if (e.wave === "tri") return p < 0.5 ? 1 - 4 * p : 4 * p - 3;
  return p < e.duty ? 1 : -1;
}

function level(e, rel) {
  if (rel < 0 || rel >= e.dur) return 0;
  if (e.env === "pluck") {                          // 2 ms attack, linear decay
    if (rel < 0.002) return e.amp * rel / 0.002;
    return e.amp * (1 - (rel - 0.002) / (e.dur - 0.002));
  }
  var a = 0.003, r = 0.008;                         // sustained: tiny attack/release
  if (rel < a) return e.amp * rel / a;
  if (rel > e.dur - r) return e.amp * (e.dur - rel) / r;
  return e.amp;
}

/* One lane = one oscillator. Phase runs free across the whole loop; a finished
   note keeps steering the frequency so the next one picks up in phase. */
function renderLane(out, events) {
  if (!events.length) return;
  events.sort(function (a, b) { return a.t - b.t; });
  var ph = 0, ei = 0, cur = null, f = hz(events[0].midi);
  for (var i = 0; i < out.length; i++) {
    var t = i / SR;
    while (ei < events.length && events[ei].t <= t) cur = events[ei++];
    if (cur) {
      f = hz(cur.midi);
      var a = level(cur, t - cur.t);
      if (a !== 0) out[i] += a * shape(cur, ph);
    }
    ph += f / SR;
    if (ph >= 1) ph -= 1;
  }
}

/* ------------------------------------------------------------ arrangements -- */

/* the original: 8th-note triangle bass + 25% pulse pluck on every 8th */
function theme() {
  var bass = [], lead = [], b = bassLine(), i;
  for (i = 0; i < 64; i++) bass.push(note(i * STEP, STEP, b[i], 0.15, "tri", 0, "hold"));
  for (i = 0; i < 32; i++) {
    if (MEL[i] === null) continue;
    lead.push(note(i * 0.25, 0.12, MEL[i], 0.15, "pulse", 0.25, "pluck"));
  }
  return { lanes: [bass, lead], rms: 0.115 };
}

/* menu / game-over reading of the same tune: bass on the half note, only the
   downbeats of the melody, and a quiet triangle pad holding the chord root */
function calm() {
  var bass = [], lead = [], pad = [], b = bassLine(), i, bar;
  for (i = 0; i < 16; i++) {                        // one bass note per half bar
    bass.push(note(i * 0.5, 0.46, b[i * 4], 0.15, "tri", 0, "hold"));
  }
  for (i = 0; i < 32; i += 2) {                     // every other melody slot
    if (MEL[i] === null) continue;
    lead.push(note(i * 0.25, 0.3, MEL[i], 0.12, "pulse", 0.25, "pluck"));
  }
  for (bar = 0; bar < 8; bar++) {                   // pad an octave above the root
    pad.push(note(bar, 0.98, BARS[bar] + 12, 0.045, "tri", 0, "hold"));
  }
  return { lanes: [bass, lead, pad], rms: 0.10 };
}

/* mid intensity: the theme untouched, plus a running arpeggio underneath and a
   pickup note in each of the melody's three rests */
function drive() {
  var t = theme(), arp = [], lead = t.lanes[1], i, bar, tones, seq = [0, 1, 2, 1, 0, 1, 2, 1];
  for (bar = 0; bar < 8; bar++) {
    for (i = 0; i < 8; i++) {
      tones = bar === 7 && i >= 4 ? [67, 71, 74] : CHORD[bar];
      arp.push(note(bar + i * STEP, 0.09, tones[seq[i]], 0.05, "pulse", 0.125, "pluck"));
    }
  }
  var fills = [[1.75, 83], [3.75, 83], [5.75, 81]];  // chord tones leading to the next phrase
  for (i = 0; i < fills.length; i++) {
    lead.push(note(fills[i][0], 0.12, fills[i][1], 0.11, "pulse", 0.25, "pluck"));
  }
  return { lanes: [t.lanes[0], lead, arp], rms: 0.118 };
}

/* full intensity: same pitches in the bass but retriggered on 16ths, the melody
   doubled a diatonic third up, and the arpeggio at double speed */
function rush() {
  var bass = [], lead = [], harm = [], arp = [], b = bassLine(), i, bar, tones;
  for (i = 0; i < 64; i++) {                        // each 8th split into two 16ths
    bass.push(note(i * STEP, 0.062, b[i], 0.15, "tri", 0, "hold"));
    bass.push(note(i * STEP + 0.0625, 0.062, b[i], 0.13, "tri", 0, "hold"));
  }
  for (i = 0; i < 32; i++) {
    if (MEL[i] === null) continue;
    lead.push(note(i * 0.25, 0.12, MEL[i], 0.14, "pulse", 0.25, "pluck"));
    harm.push(note(i * 0.25, 0.1, thirdUp(MEL[i]), 0.065, "pulse", 0.5, "pluck"));
  }
  var seq = [0, 1, 2, 1, 2, 1, 0, 1, 0, 1, 2, 1, 2, 1, 0, 1];
  for (bar = 0; bar < 8; bar++) {
    for (i = 0; i < 16; i++) {
      tones = bar === 7 && i >= 8 ? [67, 71, 74] : CHORD[bar];
      arp.push(note(bar + i * 0.0625, 0.05, tones[seq[i]], 0.045, "pulse", 0.125, "pluck"));
    }
  }
  return { lanes: [bass, lead, harm, arp], rms: 0.125 };
}

/* ----------------------------------------------------------------- output -- */

/* windowed-sinc lowpass, run before decimating so the pulse waves' harmonics
   fold nowhere; cutoff stays high enough to keep the chip edge */
function lowpass(x, cutoff) {
  var TAPS = 97, h = new Float64Array(TAPS), fc = cutoff / SR, sum = 0, i, n;
  for (i = 0; i < TAPS; i++) {
    n = i - (TAPS - 1) / 2;
    var s = n === 0 ? 2 * fc : Math.sin(2 * Math.PI * fc * n) / (Math.PI * n);
    h[i] = s * (0.54 - 0.46 * Math.cos(2 * Math.PI * i / (TAPS - 1)));
    sum += h[i];
  }
  for (i = 0; i < TAPS; i++) h[i] /= sum;
  var y = new Float64Array(x.length), mid = (TAPS - 1) / 2;
  for (i = 0; i < x.length; i++) {
    var acc = 0;
    for (var k = 0; k < TAPS; k++) {
      var j = i + k - mid;
      // wrap: the track is a loop, so the filter should be too
      if (j < 0) j += x.length; else if (j >= x.length) j -= x.length;
      acc += h[k] * x[j];
    }
    y[i] = acc;
  }
  return y;
}

function writeWav(file, samples) {
  var n = samples.length, buf = Buffer.alloc(44 + n * 2);
  buf.write("RIFF", 0, "ascii");
  buf.writeUInt32LE(36 + n * 2, 4);
  buf.write("WAVEfmt ", 8, "ascii");
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);          // PCM
  buf.writeUInt16LE(1, 22);          // mono
  buf.writeUInt32LE(RATE, 24);
  buf.writeUInt32LE(RATE * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write("data", 36, "ascii");
  buf.writeUInt32LE(n * 2, 40);
  for (var i = 0; i < n; i++) {
    var v = Math.max(-1, Math.min(1, samples[i]));
    buf.writeInt16LE(Math.round(v * 32767), 44 + i * 2);
  }
  fs.writeFileSync(file, buf);
  return buf.length;
}

function render(track, file) {
  var wide = new Float64Array(Math.round(DUR * SR)), i;
  for (i = 0; i < track.lanes.length; i++) renderLane(wide, track.lanes[i]);

  var filtered = lowpass(wide, 9800);
  var n = Math.round(DUR * RATE), out = new Float64Array(n);
  for (i = 0; i < n; i++) out[i] = filtered[i * OS];

  var sum = 0;
  for (i = 0; i < n; i++) sum += out[i] * out[i];
  var gain = track.rms / Math.sqrt(sum / n), peak = 0;
  for (i = 0; i < n; i++) {
    out[i] *= gain;
    if (Math.abs(out[i]) > peak) peak = Math.abs(out[i]);
  }
  if (peak > 0.92) {                                // headroom before the swap
    for (i = 0; i < n; i++) out[i] *= 0.92 / peak;
    peak = 0.92;
  }

  var edge = Math.round(0.002 * RATE);              // 2 ms taper kills the loop click
  for (i = 0; i < edge; i++) {
    out[i] *= i / edge;
    out[n - 1 - i] *= i / edge;
  }

  var bytes = writeWav(file, out);
  var rms = 0;
  for (i = 0; i < n; i++) rms += out[i] * out[i];
  console.log(
    path.basename(file).padEnd(18),
    (n / RATE).toFixed(3) + "s",
    (bytes / 1024).toFixed(0) + " KB",
    "peak " + peak.toFixed(3),
    "rms " + Math.sqrt(rms / n).toFixed(4)
  );
}

render(calm(), path.join(OUT, "theme_calm.wav"));
render(drive(), path.join(OUT, "theme_drive.wav"));
render(rush(), path.join(OUT, "theme_rush.wav"));
if (process.argv.indexOf("--check") >= 0) {
  render(theme(), path.join(OUT, "theme_rerender.wav"));
  console.log("wrote theme_rerender.wav for A/B against the original — delete it after");
}
