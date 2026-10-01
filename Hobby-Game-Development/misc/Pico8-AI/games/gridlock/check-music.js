// check-music.js — parses __sfx__/__music__ back out of the cart and prints them
// as note names. Headless -x never advances the audio clock, so reading the data
// back is the only way to check tempo, pitch and pattern order.
// run: node games/gridlock/check-music.js
const fs = require('fs');
const cart = fs.readFileSync(__dirname + '/game.p8', 'utf8');
const sfxLines = cart.match(/__sfx__\n([\s\S]*?)\n__music__/)[1].split('\n');
const musLines = cart.match(/__music__\n([\s\S]*?)\s*$/)[1].split('\n').filter(Boolean);
const NAMES = ['c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'];
const WAVE = ['tri', 'tsaw', 'saw', 'sqr', 'pul', 'org', 'noi', 'pha'];
const note = p => NAMES[p % 12] + Math.floor(p / 12);

sfxLines.forEach((l, i) => {
  if (l.length !== 168) { console.log('sfx ' + i + ': BAD WIDTH ' + l.length); return; }
  const speed = parseInt(l.slice(2, 4), 16);
  const out = [];
  for (let n = 0; n < 32; n++) {
    const c = l.slice(8 + n * 5, 13 + n * 5);
    const vol = parseInt(c[4 - 1], 16);
    if (vol === 0) { out.push('.'); continue; }
    const pitch = parseInt(c.slice(0, 2), 16), w = parseInt(c[2], 16);
    out.push((w === 6 ? 'nz' + pitch : note(pitch)) + '/' + (WAVE[w] || 'i' + w) + vol);
  }
  const used = out.filter(x => x !== '.').length;
  console.log('sfx ' + String(i).padStart(2) + ' spd ' + String(speed).padStart(2) +
    ' notes ' + String(used).padStart(2) + '  ' + out.join(' ').replace(/(\. )+\./g, m => '.x' + ((m.length + 1) / 2)));
});
console.log('--- patterns ---');
musLines.forEach((l, i) => {
  const flag = parseInt(l.slice(0, 2), 16);
  const ch = [0, 1, 2, 3].map(c => parseInt(l.slice(3 + c * 2, 5 + c * 2), 16));
  console.log('pat ' + i + '  ' + ch.map(v => v >= 0x40 ? '--' : 'sfx' + v).join(' ') +
    '  ' + (flag & 1 ? 'LOOPSTART ' : '') + (flag & 2 ? 'LOOPEND ' : '') + (flag & 4 ? 'STOP' : ''));
});
