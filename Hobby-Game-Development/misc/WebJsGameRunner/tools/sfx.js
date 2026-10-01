/* Offline renderer for generated sound effects. Dev tool only — nothing here
   ships or runs inside the game; it just writes wav files into assets/sfx/.

     node tools/sfx.js

   Format matches the hand-made effects already in the folder: 22050 Hz, mono,
   16-bit PCM. Everything is rendered 4x oversampled and decimated back down, so
   the square/triangle edges don't alias into a whistle up at the top notes.

   Effects rendered here:

     charge   a pulse charge is banked — a rising E5-B5-E6 chime with a bell tail,
              deliberately unlike `powerup` (which fires the pulse) so gaining a
              charge and spending one never sound like the same event.
*/

var fs = require("fs");
var path = require("path");

var RATE = 22050;
var OS = 4;                        // oversample
var SR = RATE * OS;
var OUT = path.join(__dirname, "..", "assets", "sfx");

function hz(midi) { return 440 * Math.pow(2, (midi - 69) / 12); }

/* triangle: soft, few harmonics — reads as a bell rather than a buzzer */
function tri(ph) {
  var p = ph - Math.floor(ph);
  return 4 * Math.abs(p - 0.5) - 1;
}

/* One struck note: triangle fundamental plus a quieter octave partial, both on
   an exponential decay. Phase runs free from the note's own start, so there is
   no discontinuity when the next note overlaps this one's tail. */
function note(buf, tStart, dur, freq, amp, decay) {
  var i0 = Math.round(tStart * SR);
  var i1 = Math.min(buf.length, Math.round((tStart + dur) * SR));
  var ph = 0, ph2 = 0, dp = freq / SR, dp2 = (freq * 2.01) / SR;
  for (var i = i0; i < i1; i++) {
    var t = (i - i0) / SR;
    var env = Math.exp(-t * decay);
    if (t < 0.004) env *= t / 0.004;             // 4 ms attack, kills the click
    buf[i] += (tri(ph) + 0.35 * tri(ph2)) * amp * env;
    ph += dp;
    ph2 += dp2;
  }
}

function render(name, dur, fn) {
  var wide = new Float64Array(Math.round(dur * SR));
  fn(wide);

  // one-pole lowpass at the oversampled rate, then average down to RATE
  var n = Math.round(dur * RATE), out = new Float64Array(n), i, j;
  var lp = 0, k = 1 - Math.exp(-2 * Math.PI * 6000 / SR);
  for (i = 0; i < wide.length; i++) { lp += (wide[i] - lp) * k; wide[i] = lp; }
  for (i = 0; i < n; i++) {
    var s = 0;
    for (j = 0; j < OS; j++) s += wide[i * OS + j] || 0;
    out[i] = s / OS;
  }

  var peak = 0;
  for (i = 0; i < n; i++) peak = Math.max(peak, Math.abs(out[i]));
  if (peak > 0) for (i = 0; i < n; i++) out[i] = out[i] / peak * 0.86;

  var tail = Math.round(RATE * 0.01);            // fade the last 10 ms to zero
  for (i = n - tail; i < n; i++) out[i] *= (n - i) / tail;

  var file = path.join(OUT, name + ".wav");
  var bytes = writeWav(file, out);
  console.log(name.padEnd(10), (n / RATE).toFixed(3) + "s", (bytes / 1024).toFixed(0) + " KB");
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

/* E5 B5 E6 in 55 ms steps: the first two are clipped short by the next strike,
   the last one is left to ring — an "it's in the tank" flick upward. */
render("charge", 0.42, function (b) {
  note(b, 0.000, 0.10, hz(76), 0.55, 26);        // E5
  note(b, 0.055, 0.10, hz(83), 0.60, 24);        // B5
  note(b, 0.110, 0.31, hz(88), 0.70, 9);         // E6, rings out
  note(b, 0.110, 0.31, hz(95), 0.16, 11);        // faint B6 shimmer on top
});
