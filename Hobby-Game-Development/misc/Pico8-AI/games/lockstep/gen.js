// gen.js — builds lockstep's assets and splices them into game.p8.
//   node gen.js
// Rewrites: the level table between --<levels>/--</levels>, plus __gfx__,
// __sfx__ and __music__. Level strings come straight out of the design doc,
// so the cart can never drift from it.
const fs = require('fs');
const path = require('path');
const HERE = __dirname;

// ---------------------------------------------------------------- levels

function readLevels() {
  const md = fs.readFileSync(path.join(HERE, 'lockstep-design.md'), 'utf8').split(/\r?\n/);
  const out = [];
  for (let i = 0; i < md.length; i++) {
    if (!/^### Level \d+$/.test(md[i])) continue;
    let j = i;
    while (md[j] !== '```') j++;
    const rows = [];
    for (j++; md[j] !== '```'; j++) rows.push(md[j].padEnd(14, ' '));
    if (rows.length !== 14) throw new Error(`level at line ${i}: ${rows.length} rows`);
    for (const r of rows) {
      if (r.length !== 14) throw new Error(`row wrong width: "${r}"`);
      for (const c of r) if (!'# .$*@+'.includes(c)) throw new Error(`bad char "${c}"`);
    }
    out.push(rows.join(''));
  }
  if (out.length !== 25) throw new Error(`expected 25 levels, got ${out.length}`);
  return out;
}

// ------------------------------------------------------------------- gfx

// Sprite sheet. 'e' (colour 14) is the transparency key -- the cart calls
// palt(0,false) palt(14,true), which frees colour 0 to be a real black
// outline on every sprite. No sprite may use pink for anything else, and
// pcl (the per-player body colours) must never contain 14.
//
//   0        blank
//   1,2      floor variants
//   3,4,5    wall variants
//   6        crate
//   7..10    star, 4-frame twinkle
//   11,12    padlock, 2-frame rattle
//   13       cursor corner bracket (top-left; flipped for the other three)
//   14..17   goal tile, 4-frame outward pulse
//   18..21   crate on goal, 4-frame shine
//   22..25   player idle, 4-frame breathe/blink
//   26,27    player step: stretch, squash
//   28..31   goal-locked starburst, 4 frames

const SPRITES = {
  1: [ // floor a -- dark seam on the top/left edge draws the tile grid
    '00000000',
    '01111111',
    '01111111',
    '01111111',
    '01111111',
    '01111111',
    '01111111',
    '01111111',
  ],
  2: [ // floor b -- same tile with a little grit
    '00000000',
    '01111111',
    '01111111',
    '011d1111',
    '01111111',
    '01111111',
    '0111d111',
    '01111111',
  ],
  3: [ // wall a -- top-lit bevel, shadow down the right and bottom
    '66666666',
    '65555550',
    '65555550',
    '65555550',
    '65555550',
    '65555550',
    '65555550',
    '00000000',
  ],
  4: [ // wall b -- chipped
    '66666666',
    '65565550',
    '65555550',
    '65555650',
    '65555550',
    '65655550',
    '65555550',
    '00000000',
  ],
  5: [ // wall c -- cracked
    '66666666',
    '65555550',
    '65551550',
    '65551550',
    '65515550',
    '65555550',
    '65555550',
    '00000000',
  ],
  6: [ // crate -- peach rim, brown planks, orange cross brace
    '00000000',
    '0ffffff0',
    '0f9449f0',
    '0f4994f0',
    '0f4994f0',
    '0f9449f0',
    '0ffffff0',
    '00000000',
  ],
  11: [ // padlock, shut. 7 rows: row 8 must stay clear of the tile border
    'eee66eee',
    'ee6ee6ee',
    'e666666e',
    'e660066e',
    'e666666e',
    'e555555e',
    'eeeeeeee',
    'eeeeeeee',
  ],
  12: [ // padlock, shackle rattled left
    'ee66eeee',
    'e6ee6eee',
    'e666666e',
    'e660066e',
    'e666666e',
    'e555555e',
    'eeeeeeee',
    'eeeeeeee',
  ],
  13: [ // cursor bracket, top-left corner
    'aaaaaeee',
    'a0000eee',
    'a0eeeeee',
    'a0eeeeee',
    'a0eeeeee',
    'eeeeeeee',
    'eeeeeeee',
    'eeeeeeee',
  ],
};

// ---- star: a cut gem with a glint that slides across it
const STAR = [
  'ee00eeee',
  'e0GG0eee',
  '0GHHG0ee',
  '0GGGG0ee',
  'e0GG0eee',
  'ee00eeee',
  'eeeeeeee',
  'eeeeeeee',
];
// [body, glint] per frame; frame 2 dims the whole gem so it reads as a blink
[['a', 'a'], ['a', '7'], ['9', 'a'], ['a', '7']].forEach(([g, h], f) => {
  SPRITES[7 + f] = STAR.map(r => r.split('G').join(g).split('H').join(h));
});
// widen the glint on the bright frame, slide it right on the last one
SPRITES[8][2] = '077770ee';
SPRITES[10][3] = '0a77a0ee';

// ---- goal: a standing ring plus a highlight that pulses out from the centre
function goal(frame) {
  const g = SPRITES[1].map(r => [...r]);            // floor a is the base
  const put = (x, y, c) => { g[y][x] = c; };
  const ring = (r, c) => {                          // chebyshev ring about (4,4)
    for (let y = 4 - r; y <= 4 + r; y++)
      for (let x = 4 - r; x <= 4 + r; x++)
        if (Math.max(Math.abs(x - 4), Math.abs(y - 4)) === r) put(x, y, c);
  };
  ring(2, '3');                                     // the goal always shows
  if (frame === 0) put(4, 4, 'b');
  if (frame === 1) ring(1, 'b');
  if (frame === 2) ring(2, 'b');
  return g.map(r => r.join(''));
}
for (let f = 0; f < 4; f++) SPRITES[14 + f] = goal(f);

// ---- crate on goal: the crate palette-shifted to green, with a shine that
// travels top rim -> brace -> bottom rim -> off
const ONGOAL = [
  '00000000',
  '0RRRRRR0',
  '0RR33RR0',
  '0R3RR3R0',
  '0R3RR3R0',
  '0RR33RR0',
  '0RRRRRR0',
  '00000000',
];
for (let f = 0; f < 4; f++) {
  const g = ONGOAL.map(r => r.split('R').join('b'));
  if (f === 1) g[1] = '07777770';
  if (f === 2) { g[3] = '0b3773b0'; g[4] = '0b3773b0'; }
  if (f === 3) g[6] = '07777770';
  SPRITES[18 + f] = g;
}

// ---- player. Body is colour 7 and shading is colour 6; the cart swaps both
// per player, so every player reads as one hue with its own darker shade.
SPRITES[22] = [
  'ee0000ee',
  'e077770e',
  '07777770',
  '07077070',
  '07777770',
  '06777760',
  'e066660e',
  'ee0000ee',
];
SPRITES[23] = [ // settle: the whole body drops a pixel
  'eeeeeeee',
  'ee0000ee',
  'e077770e',
  '07077070',
  '07777770',
  '06777760',
  'e066660e',
  'ee0000ee',
];
SPRITES[24] = SPRITES[22];
SPRITES[25] = [ // eyes drop -- reads as a blink at speed
  'ee0000ee',
  'e077770e',
  '07777770',
  '07777770',
  '07077070',
  '06777760',
  'e066660e',
  'ee0000ee',
];
SPRITES[26] = [ // step: stretched tall
  'ee0000ee',
  'e077770e',
  '07777770',
  '07077070',
  '07777770',
  '07777770',
  'e077770e',
  'ee0000ee',
];
SPRITES[27] = [ // landing: squashed wide
  'eeeeeeee',
  'eeeeeeee',
  'e000000e',
  '07077070',
  '07777770',
  '06777760',
  '06666660',
  'e000000e',
];

// ---- starburst played over a crate the moment it locks onto a goal
for (let f = 0; f < 4; f++) {
  const g = Array.from({ length: 8 }, () => Array(8).fill('e'));
  const c = f < 2 ? '7' : 'a';
  const put = (x, y) => { if (x >= 0 && x < 8 && y >= 0 && y < 8) g[y][x] = c; };
  for (let k = (f === 3 ? f : 0); k <= f; k++) {    // the last frame keeps only the tips
    for (const d of [3, 4]) {
      put(d, 3 - k); put(d, 4 + k); put(3 - k, d); put(4 + k, d);
    }
  }
  SPRITES[28 + f] = g.map(r => r.join(''));
}

function gfx() {
  const rows = 4;                                   // 4 sprite rows = sprites 0..63
  const sheet = [];
  for (let y = 0; y < rows * 8; y++) sheet.push(Array(128).fill('0'));
  for (const [n, art] of Object.entries(SPRITES)) {
    const sx = (n % 16) * 8, sy = Math.floor(n / 16) * 8;
    if (art.length !== 8) throw new Error(`sprite ${n}: ${art.length} rows`);
    art.forEach((row, y) => {
      if (row.length !== 8) throw new Error(`sprite ${n} row ${y}: "${row}"`);
      [...row].forEach((c, x) => {
        if (!/[0-9a-f]/.test(c)) throw new Error(`sprite ${n}: bad colour "${c}"`);
        sheet[sy + y][sx + x] = c;
      });
    });
  }
  // tiles are drawn edge to edge, so they must be fully opaque
  for (const n of [1, 2, 3, 4, 5, 14, 15, 16, 17]) {
    if (SPRITES[n].join('').includes('e')) throw new Error(`tile ${n} has a hole`);
  }
  return sheet.map(r => r.join(''));
}

// ------------------------------------------------------------------- sfx

const h2 = n => n.toString(16).padStart(2, '0');
const h1 = n => n.toString(16);
const REST = '00000';
const note = (pitch, wave, vol, fx = 0) => h2(pitch) + h1(wave) + h1(vol) + h1(fx);

function sfxline(speed, notes, loopStart = 0, loopEnd = 0) {
  const ns = notes.slice(0, 32);
  while (ns.length < 32) ns.push(REST);
  const line = '01' + h2(speed) + h2(loopStart) + h2(loopEnd) + ns.join('');
  if (line.length !== 168) throw new Error(`sfx line is ${line.length} chars`);
  return line;
}

const TRI = 0, SAW = 2, SQR = 3, PLS = 4, ORG = 5, NSE = 6, PHS = 7;
const FADEIN = 4, FADEOUT = 5, DROP = 3, VIB = 2;

const sfx = [];
// 0 — step blips, one note per direction: sfx(0,3,dir,1)
sfx[0] = sfxline(8, [
  note(24, ORG, 4, FADEOUT), // left
  note(28, ORG, 4, FADEOUT), // right
  note(33, ORG, 4, FADEOUT), // up
  note(20, ORG, 4, FADEOUT), // down
]);
// 1 — bump: muted thud
sfx[1] = sfxline(9, [note(8, NSE, 3, DROP), note(5, NSE, 2, FADEOUT)]);
// 2 — box slide: low scrape under the step
sfx[2] = sfxline(7, [note(14, NSE, 2, VIB), note(12, NSE, 2, VIB), note(10, NSE, 1, FADEOUT)]);
// 3 — goal locked: 4 two-note chimes, rising. sfx(3,1,(n-1)*2,2)
sfx[3] = sfxline(11, [
  note(36, TRI, 5, 0), note(43, TRI, 5, FADEOUT),
  note(38, TRI, 5, 0), note(45, TRI, 5, FADEOUT),
  note(40, TRI, 5, 0), note(47, TRI, 5, FADEOUT),
  note(43, TRI, 6, 0), note(50, TRI, 6, FADEOUT),
]);
// 4 — goal unlocked: the chime inverted and quieter
sfx[4] = sfxline(11, [note(43, TRI, 3, 0), note(36, TRI, 3, FADEOUT)]);
// 5 — solve fanfare
sfx[5] = sfxline(10, [
  note(36, ORG, 5, 0), note(40, ORG, 5, 0), note(43, ORG, 5, 0),
  note(48, ORG, 6, 0), note(48, ORG, 5, FADEOUT), note(48, ORG, 3, FADEOUT),
]);
// 6 — undo: a short reversed blip
sfx[6] = sfxline(8, [note(22, ORG, 3, FADEIN), note(18, ORG, 3, FADEOUT)]);
// 7 — menu tick
sfx[7] = sfxline(6, [note(30, SQR, 3, FADEOUT)]);

// 12 — blown the move budget: a noise burst that falls away
sfx[12] = sfxline(9, [
  note(24, NSE, 6, DROP), note(19, NSE, 6, DROP), note(14, NSE, 5, DROP),
  note(10, NSE, 4, FADEOUT), note(6, NSE, 3, FADEOUT), note(3, NSE, 2, FADEOUT),
]);

// 8..11 — the ambient bed. Two patterns, bass + pad, deliberately sparse.
function droneBass(pitches) {           // 4 pitches, 8 notes each
  const ns = [];
  for (const p of pitches) {
    ns.push(note(p, TRI, 3, 0));
    for (let i = 0; i < 6; i++) ns.push(note(p, TRI, 2, 0));
    ns.push(note(p, TRI, 1, FADEOUT));
  }
  return ns;
}
function padVoice(pitches) {            // 8 pitches, 4 notes each
  const ns = [];
  for (const p of pitches) {
    ns.push(note(p, ORG, 2, 0), note(p, ORG, 1, 0), note(p, ORG, 1, FADEOUT), REST);
  }
  return ns;
}
sfx[8] = sfxline(26, droneBass([21, 16, 19, 17]));       // a f c d (low)
sfx[9] = sfxline(26, padVoice([45, 48, 40, 45, 43, 47, 40, 45]));
sfx[10] = sfxline(26, droneBass([21, 14, 19, 16]));
sfx[11] = sfxline(26, padVoice([48, 52, 45, 48, 43, 45, 40, 36]));

// ----------------------------------------------------------------- music

// pattern 0 is loop start, pattern 1 is loop end -> 0,1,0,1,...
const music = [
  '01 08094344',
  '02 0a0b4344',
];

// ------------------------------------------------------------- splice it

const cartPath = path.join(HERE, 'game.p8');
let cart = fs.readFileSync(cartPath, 'utf8');

const levels = readLevels();
const lvlBlock = 'lvs={\n' +
  levels.map((s, i) => ` "${s}", -- ${i + 1}`).join('\n') +
  '\n}';
// The replacement MUST be a function: a literal `$$` in the level data (level
// 25 has one) is otherwise eaten by String.replace's substitution syntax.
cart = cart.replace(/--<levels>\r?\n[\s\S]*?--<\/levels>/,
  () => '--<levels>\n' + lvlBlock + '\n--</levels>');

function section(name, lines) {
  const re = new RegExp(`__${name}__\\r?\\n(?:(?!__[a-z]+__)[^\\n]*\\r?\\n)*`, 'm');
  const body = `__${name}__\n` + (lines.length ? lines.join('\n') + '\n' : '');
  if (!re.test(cart)) throw new Error(`no __${name}__ section`);
  cart = cart.replace(re, () => body);
}

const g = gfx();
g.forEach((l, i) => { if (l.length !== 128) throw new Error(`gfx line ${i}: ${l.length}`); });
section('gfx', g);
section('sfx', sfx.map((l, i) => l ?? sfxline(1, [])));
section('music', music);
cart = cart.replace(/__gff__\n/, '');   // no sprite flags in this game

// read the level strings back out of the cart we are about to write, so a
// mangled splice can never ship
const back = [...cart.matchAll(/^ "(.*)", -- \d+$/gm)].map(m => m[1]);
if (back.length !== 25) throw new Error(`spliced ${back.length} levels`);
back.forEach((s, i) => {
  if (s !== levels[i]) throw new Error(`level ${i + 1} mangled by splice (${s.length} chars)`);
});

fs.writeFileSync(cartPath, cart);

// labelgen.p8 draws the cover art with the game's own sprites, so keep its
// sheet in sync with the cart's
const lgPath = path.join(HERE, 'labelgen.p8');
if (fs.existsSync(lgPath)) {
  let lg = fs.readFileSync(lgPath, 'utf8');
  lg = lg.replace(/__gfx__\n[\s\S]*$/, () => '__gfx__\n' + g.join('\n') + '\n');
  fs.writeFileSync(lgPath, lg);
  console.log('synced labelgen.p8 sprite sheet');
}
console.log(`levels: ${levels.length} x ${levels[0].length} chars`);
console.log(`gfx: ${g.length} lines, sfx: ${sfx.length} slots, music: ${music.length} patterns`);
console.log(`wrote ${cartPath} (${cart.length} bytes)`);
