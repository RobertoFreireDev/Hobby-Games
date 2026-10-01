// gen.js — regenerate the __gfx__ / __sfx__ / __music__ sections of game.p8
// for PEG DUNGEON.  Sprites are authored as ASCII art below, one char per pixel.
// usage: node gen.js
const fs = require('fs');
const path = require('path');
const CART = path.join(__dirname, 'game.p8');

// ---------------------------------------------------------------- sprites
// '.' = colour 0 (transparent).  Everything else is a literal hex digit.
// Carriers have no base row; every enemy has a 1px root row in colour 2 so
// "rooted vs movable" is legible without selecting.
const SPR = {};

SPR[1] = [                      // rubble
  '........',
  '........',
  '..5665..',
  '.566665.',
  '.566655.',
  '.556655.',
  '..5555..',
  '........',
];
SPR[2] = [                      // potion
  '........',
  '..6666..',
  '..6bb6..',
  '.66bb66.',
  '.6bbbb6.',
  '.6b7bb6.',
  '..6666..',
  '........',
];
SPR[3] = [                      // sword
  '........',
  '...7....',
  '..667...',
  '..667...',
  '..667...',
  '.44444..',
  '...44...',
  '........',
];
SPR[4] = [                      // enemy tier 1 — small, indigo
  '........',
  '........',
  '...dd...',
  '..d77d..',
  '..dddd..',
  '...dd...',
  '..2222..',
  '........',
];
SPR[5] = [                      // enemy tier 2 — bigger silhouette, pink
  '........',
  '..eeee..',
  '.eeeeee.',
  '.e7ee7e.',
  '.eeeeee.',
  '.eeeeee.',
  '.222222.',
  '........',
];
SPR[6] = [                      // enemy tier 3 — horned, orange accent
  '.9....9.',
  '.9eeee9.',
  '.eeeeee.',
  '.e7ee7e.',
  '.eeeeee.',
  '.e8ee8e.',
  '.222222.',
  '........',
];
SPR[7] = [                      // enemy tier 4 — rare, red, spiked
  '..8..8..',
  '.888888.',
  '.8a88a8.',
  '.888888.',
  '.8.88.8.',
  '.888888.',
  '.222222.',
  '........',
];
SPR[8] = [                      // heart icon
  '........',
  '.88.88..',
  '8888888.',
  '8888888.',
  '.88888..',
  '..888...',
  '...8....',
  '........',
];
SPR[9] = [                      // sword icon
  '........',
  '.....67.',
  '....67..',
  '...67...',
  '..464...',
  '.44.....',
  '.4......',
  '........',
];
SPR[10] = [                     // flask icon
  '........',
  '..66....',
  '..6b6...',
  '.66bb6..',
  '.6bbb6..',
  '.6bbb6..',
  '.66666..',
  '........',
];
SPR[11] = [                     // skull icon
  '........',
  '.77777..',
  '.70707..',
  '.77777..',
  '..777...',
  '.7.7.7..',
  '........',
  '........',
];

SPR[12] = [                     // chipped sword icon (dur <= 2)
  '........',
  '.....67.',
  '....6...',
  '...67...',
  '..464...',
  '.44.....',
  '.4......',
  '........',
];

function gfx() {
  const lines = [];
  for (let y = 0; y < 8; y++) {
    let row = '00000000';                 // sprite 0 stays blank
    for (let n = 1; n <= 12; n++) {
      const art = SPR[n];
      if (!art || art.length !== 8) throw new Error('sprite ' + n + ' not 8 rows');
      const r = art[y];
      if (r.length !== 8) throw new Error('sprite ' + n + ' row ' + y + ' not 8 wide');
      row += r.replace(/\./g, '0');
    }
    lines.push(row.padEnd(128, '0'));
  }
  for (const l of lines) if (l.length !== 128) throw new Error('gfx width');
  return lines;
}

// ---------------------------------------------------------------- sfx
// note = [pitch, waveform, volume, effect]; null = rest.
function sfxline(speed, notes, loopStart, loopEnd) {
  let s = '01'
    + speed.toString(16).padStart(2, '0')
    + (loopStart || 0).toString(16).padStart(2, '0')
    + (loopEnd || 0).toString(16).padStart(2, '0');
  for (let i = 0; i < 32; i++) {
    const n = notes[i];
    if (!n) { s += '00000'; continue; }
    const [p, w, v, e] = n;
    s += p.toString(16).padStart(2, '0') + w.toString(16) + v.toString(16) + (e || 0).toString(16);
  }
  if (s.length !== 168) throw new Error('sfx width ' + s.length);
  return s;
}

// build a run of notes from a pitch list
const run = (pitches, w, v, e) => pitches.map(p => (p === null ? null : [p, w, v, e || 0]));

const SFX = [];
SFX[0] = sfxline(4, run([34], 5, 1));                                  // cursor
SFX[1] = sfxline(5, run([28, 35], 3, 3));                              // select
SFX[2] = sfxline(7, run([8, 6], 6, 4));                                // refused buzz
SFX[3] = sfxline(3, run([22, 27, 31], 1, 3, 1));                       // jump arc
SFX[4] = sfxline(6, run([18, 12, 8], 6, 5, 3));                        // hit taken
SFX[5] = sfxline(4, run([45, 40], 3, 4, 3));                           // no-damage clang
SFX[6] = sfxline(8, run([40, 34, 28, 22, 17, 12, 8, 4], 6, 5, 5));     // sword shatter
SFX[7] = sfxline(7, run([20, 24, 27, 32], 5, 3));                      // potion drink
SFX[8] = sfxline(5, run([28, 33, 38], 2, 4));                          // item pickup
SFX[9] = sfxline(6, run([24, 28, 31, 36, 40], 5, 5));                  // level up
SFX[10] = sfxline(10, run([24, 28, 31, 36, 36, 40], 3, 5));            // win fanfare
SFX[11] = sfxline(14, run([24, 20, 17, 12, 8], 0, 5, 5));              // death sting

// ambient bed: two long low patterns, quiet, triangle
const bedA = [];
const bedB = [];
for (let i = 0; i < 32; i++) {
  bedA.push(i % 8 === 0 ? [[10, 15, 8, 13][(i / 8) | 0], 0, 2, 2] : null);
  bedB.push(i % 8 === 4 ? [[22, 25, 20, 17][(i / 8) | 0], 5, 1, 2] : null);
}
SFX[12] = sfxline(28, bedA);
SFX[13] = sfxline(28, bedB);

// ---------------------------------------------------------------- music
// pattern 0 = loop start, pattern 1 = loop end; both play bass + pad.
const MUSIC = [
  '01 0c0d4344',
  '02 0d0c4344',
];

// ---------------------------------------------------------------- splice
const cart = fs.readFileSync(CART, 'utf8');
const cut = cart.search(/^__gfx__$/m);
if (cut < 0) throw new Error('no __gfx__ marker in game.p8');

// __label__ is produced by labelgen.p8 + label-tool.js, not here — carry it
// through untouched, and keep it in its required slot after __gfx__.
const lab = cart.match(/^__label__$\n(?:[0-9a-f]{128}\n)+/m);

const out = cart.slice(0, cut)
  + '__gfx__\n' + gfx().join('\n') + '\n'
  + (lab ? lab[0] : '')
  + '__sfx__\n' + SFX.map(l => l).join('\n') + '\n'
  + '__music__\n' + MUSIC.join('\n') + '\n';

fs.writeFileSync(CART, out);
console.log('wrote', CART, '-', gfx().length, 'gfx lines,', SFX.length, 'sfx,', MUSIC.length, 'music');
