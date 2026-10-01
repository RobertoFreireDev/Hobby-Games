// ringart.js -- procedural art for the playing pieces and the HUD pip.
//
// The pieces are ellipsoid creatures with a face. Only ONE of each is drawn;
// the seven colour slots are produced at runtime with pal(), so the sheet holds
// a single template whose colours are:
//   0 outline   8 body   2 shade   14 highlight   1 transparent
// slot 0 (red) happens to be the identity mapping.
//
// The eyes are colours 7 and 0, which pal() never touches, so every creature
// gets the same face no matter which body colour it is wearing.
'use strict';

const OUT = '0', BODY = '8', SHADE = '2', HI = 'e', CLEAR = '1', WHITE = '7';

// squared normalised radius of an ellipse at pixel centre (x+.5, y+.5)
function ell(x, y, cx, cy, rx, ry) {
  const dx = (x + 0.5 - cx) / rx, dy = (y + 0.5 - cy) / ry;
  return dx * dx + dy * dy;
}

// ------------------------------------------------------------------- the face
//
// Three states on the same body:
//   calm   a pair of 3x3 eyes with a centred pupil
//   angry  eyes a row lower, a stair-step brow slanting down towards the nose,
//          and both pupils shoved to their inner edge -- so a refused pair
//          reads as two creatures glaring at each other, not at the player
//   blink  the lids down, a 3px dash where each eye was
//
// All three sit in rows 2..6 of a 9-row body. Stacked pieces are 6px apart, so
// the piece above covers rows 0..2 of the one below: rows 3+ are always visible
// and only the top of a stack (never covered) can be the one wearing a brow.
const EYE_L = 7, EYE_R = 14, EYE_W = 3;   // eye columns 7-9 and 14-16

function face(mode) {
  const px = {};                                   // "x,y" -> colour
  const set = (x, y, c) => { px[x + ',' + y] = c; };
  const angry = mode === 'angry';
  const top = angry ? 4 : 3;
  if (mode === 'blink') {
    for (const ex of [EYE_L, EYE_R]) {
      for (let x = ex; x < ex + EYE_W; x++) set(x, top + 1, OUT);
    }
    return px;
  }
  for (const ex of [EYE_L, EYE_R]) {
    for (let y = top; y < top + 3; y++) {
      for (let x = ex; x < ex + EYE_W; x++) set(x, y, WHITE);
    }
  }
  if (angry) {
    // brows: outer pixel pair high, inner pair a row lower
    set(6, 2, OUT); set(7, 2, OUT); set(8, 3, OUT); set(9, 3, OUT);
    set(17, 2, OUT); set(16, 2, OUT); set(15, 3, OUT); set(14, 3, OUT);
    set(EYE_L + 2, top + 1, OUT); set(EYE_R, top + 1, OUT);   // pupils, inward
  } else {
    set(EYE_L + 1, top + 1, OUT); set(EYE_R + 1, top + 1, OUT);
  }
  return px;
}

// -------------------------------------------------------------------- the body
//
// A 24x9 ellipsoid lit from the upper left, with a dither band across each
// tone break (design 8.2). rx=11 / ry=4.5 is what gives the silhouette its
// 10 / 16 / 20 / 22 px rows -- wide enough for a face, narrow enough at the
// crown that a stack still reads as separate heads.
function blob(mode) {
  const w = 24, h = 9, cx = 12, cy = 4.5, rx = 11, ry = 4.5;
  const inB = (x, y) => x >= 0 && x < w && y >= 0 && y < h && ell(x, y, cx, cy, rx, ry) <= 1.0;
  const f = face(mode);

  const g = [];
  for (let y = 0; y < h; y++) {
    const row = [];
    for (let x = 0; x < w; x++) {
      if (!inB(x, y)) { row.push(CLEAR); continue; }
      if (!inB(x - 1, y) || !inB(x + 1, y) || !inB(x, y - 1) || !inB(x, y + 1)) {
        row.push(OUT); continue;
      }
      const fc = f[x + ',' + y];
      if (fc) { row.push(fc); continue; }
      const dx = (x + 0.5 - cx) / rx, dy = (y + 0.5 - cy) / ry;
      const t = dy * 0.95 + dx * 0.30;
      const chk = (x + y) % 2 === 0;
      let c;
      if (t < -0.42) c = HI;
      else if (t < -0.18) c = chk ? HI : BODY;
      else if (t < 0.24) c = BODY;
      else if (t < 0.50) c = chk ? BODY : SHADE;
      else c = SHADE;
      row.push(c);
    }
    g.push(row.join(''));
  }
  return g;
}

// 8x8 pip for the rule HUD: the same creature seen small. There is room for one
// pixel per eye, so angry is those pixels dropped a row with an outer-upper
// pixel added -- two short diagonals leaning towards the nose.
function pip(angry) {
  const g = [];
  const inC = (x, y) => x >= 0 && x < 8 && y >= 0 && y < 8 && ell(x, y, 4, 4, 3.6, 3.6) <= 1.0;
  const eyes = angry
    ? { '1,3': 1, '6,3': 1, '2,4': 1, '5,4': 1 }
    : { '2,3': 1, '5,3': 1 };
  for (let y = 0; y < 8; y++) {
    const row = [];
    for (let x = 0; x < 8; x++) {
      if (!inC(x, y)) { row.push(CLEAR); continue; }
      if (!inC(x - 1, y) || !inC(x + 1, y) || !inC(x, y - 1) || !inC(x, y + 1)) { row.push(OUT); continue; }
      if (eyes[x + ',' + y]) { row.push(OUT); continue; }
      const dx = (x + 0.5 - 4) / 3.6, dy = (y + 0.5 - 4) / 3.6;
      const t = dy * 0.9 + dx * 0.45;
      const chk = (x + y) % 2 === 0;
      let c;
      if (t < -0.30) c = HI;
      else if (t < 0.10) c = BODY;
      else if (t < 0.42) c = chk ? BODY : SHADE;
      else c = SHADE;
      row.push(c);
    }
    g.push(row.join(''));
  }
  return g;
}

module.exports = { blob, pip };

if (require.main === module) {
  const show = (g) => console.log(g.map((r) => r.replace(/1/g, '.')).join('\n') + '\n');
  console.log('calm 24x9:'); show(blob('calm'));
  console.log('angry 24x9:'); show(blob('angry'));
  console.log('blink 24x9:'); show(blob('blink'));
  console.log('pip calm:'); show(pip(false));
  console.log('pip angry:'); show(pip(true));
}
