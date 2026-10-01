// gen-sprites.js -- MOONFALL sprite sheet, Castlevania-SNES art direction
//
// Exports buildGfx() for build.js; run directly for an ASCII preview, or use
// sheet-preview.js for a PNG.
//
// Sheet layout, in 16x16 tiles. Tile (tx,ty) is sprite ty*32 + tx*2.
//   ty=0  the eight villagers
//   ty=1  chapel mill inn forge graveyard manor watchtower well
//   ty=2  mountain forest lake ground player wolf
//
// ---------------------------------------------------------------------------
// HOW THE ART IS AUTHORED
//
// Not as colours. Every pixel is a *material*, and a shader assigns the colour
// from a three-step ramp according to which way the surface faces. That is the
// whole trick behind the 16-bit look: a flat fill reads as a sticker, a ramp
// reads as a lit solid, and doing it by rule rather than by hand is what keeps
// twenty-two tiles looking like one artist drew them.
//
// The rules, all of which follow from a single decision -- the moon is up and
// to the left, and it never moves:
//
//   * a pixel whose neighbour above or to the left is a different material is
//     facing the moon      -> ramp[0], highlight
//   * a pixel whose neighbour below or to the right is different is turning
//     away                 -> ramp[2], shadow
//   * everything else is flat to the light -> ramp[1], the material's own hue
//   * one pixel further in from a shadow edge, on a checkerboard, also takes
//     the shadow tone -- the dither that stands in for the fourth colour a
//     16-colour palette does not have
//
// Consequences worth knowing when drawing: an opening punched in a wall gets a
// dark lintel above and a bright sill below for free, and a stack of tiers
// (a spruce, a mansard roof) separates itself without a single drawn line.
//
// Two passes then finish the tile:
//
//   * LAMPLIGHT. Stone and timber orthogonally touching a lit window warm up one
//     step. Castlevania is cold blue stone with warm light bleeding out of it;
//     light that does not touch anything is just a yellow rectangle.
//   * CONTACT SHADOW. Ground one pixel down-and-right of any solid takes black,
//     two pixels away on a dither. Nothing is allowed to float.
//
// Board tiles are opaque and carry their own ground (the 'G' passthrough
// samples the ground tile at the same coordinate, so the seam between a
// landmark and the cell it stands in is invisible). Figures use 0 as
// transparency, get an automatic outline in the state colour, and therefore
// may never contain literal black -- their shadows bottom out at 1 or 2.
// ---------------------------------------------------------------------------

'use strict';

// Literal colours, for the handful of things that are their own light source or
// too small to shade: windows, eyes, embers, rope.
const LIT = { k:0, n:1, u:2, v:3, w:4, d:5, l:6, h:7, r:8, o:9, y:10, m:11, b:12, i:13, p:14, s:15 };

// Materials: [facing the moon, flat, turned away].
const MAT = {
  S: [6, 5, 1],      // cut stone -- grey lit, blue in shadow. Moonlight is cold
  R: [13, 2, 0],     // slate roof
  W: [4, 2, 1],      // timber. Brown at best: orange is lamplight, not wood
  T: [9, 4, 2],      // thatch
  I: [6, 5, 0],      // wrought iron
  E: [4, 2, 1],      // turned earth
  F: [11, 3, 1],     // foliage
  A: [12, 12, 1],    // water: no rim highlight, only the moon on it
  M: [6, 5, 1],      // bare rock
  N: [7, 6, 13],     // snow
  L: [7, 6, 5],      // linen, pale cloth
  D: [5, 1, 1],      // dark cloth. Never bottoms out at 0 -- see the header
  K: [15, 15, 4],    // skin
  C: [11, 12, 13],   // cloak: PLACEHOLDERS, remapped per villager by the cart
};

// The cart re-maps these four indices on every figure it draws. Nothing else in
// a figure tile may produce them, or a villager's hue would leak into their
// face. buildGfx() enforces it.
const OUTLINE = 3, CLOAK_HI = 11, CLOAK_MID = 12, CLOAK_LO = 13;
const RESERVED = [OUTLINE, CLOAK_HI, CLOAK_MID, CLOAK_LO];

// Per-villager cloak ramp, in the cart's order. hue[] is the mid tone and is
// also what the notebook prints its pips in, so that is the one that has to
// stay the character's stated colour (design section 2).
const HUE = [7, 3, 4, 9, 8, 5, 2, 12];        // bela mara otto vesna dragan luka iris stefan
const HHI = [7, 11, 9, 10, 14, 6, 13, 6];
const HLO = [5, 1, 2, 4, 2, 1, 1, 1];

// ---------------------------------------------------------------- ground

// Base 1 with 13 tufts and the odd 5 pebble; the dotted black seam down the
// right edge and along the bottom is what makes the 6x6 grid legible without
// drawing a grid over it. The grid is the evidence (design section 3), so it
// has to read.
const GROUND = [
  'nnnnnnnnnnnnnnnk',
  'nnnnnnnnnnnnnnnn',
  'nnnnnnnnnnnnnnnk',
  'nnnnnnnnnndnnnnn',
  'nnnnnnnnnnknnnnk',
  'nndnnnnnnnnnnnnn',
  'nnknnnnnnnnnnnnk',
  'nnnnnnnnnnnnnnnn',
  'nnnnnnnndnnnnnnk',
  'nnnnnnnnknnnnnnn',
  'nnnnnnnnnnnnnnnk',
  'nnnnnnnnnnnnndnn',
  'nnnnnnnnnnnnnnkk',
  'nnnnnnnnnnnnnnnn',
  'nnnnnnnnnnnnnnnk',
  'knknknknknknknkn',
];

// ---------------------------------------------------------------- landmarks

const CHAPEL = [
  'GGGGGGGIGGGGGGGG',
  'GGGGGGIIIGGGGGGG',
  'GGGGGGGIGGGGGGGG',
  'GGGGGGGRRGGGGGGG',
  'GGGGGGRRRRGGGGGG',
  'GGGGGRRRRRRGGGGG',
  'GGGGRRRRRRRRGGGG',
  'GGGRRRRRRRRRRGGG',
  'GGRRRRRRRRRRRRGG',
  'GGGSSSSyySSSSGGG',
  'GGGSSSoyyoSSSGGG',
  'GGGSSSSooSSSSGGG',
  'GGGSySSSSSSySGGG',
  'GGGSySSkkSSySGGG',
  'GGGSSSSkkSSSSGGG',
  'GGGGGGGGGGGGGGGG',
];

// The wheel is a ring with four spokes, drawn as an ellipse so it reads round
// at 8x10 rather than as an octagon. otto complains about it (design section 2).
const MILL = [
  'GGGGGGGGGGGGGGGG',
  'GGGGGGGGTTTTTTTG',
  'GGGGGGGTTTTTTTTG',
  'GGGGGGTTTTTTTTTG',
  'GGGGGGGGWWWWWWWG',
  'GGGIIGGGWWyyWWWG',
  'GIIIIIIGWWyyWWWG',
  'IIGIIGIIWWWWWWWG',
  'IGGIIGGIWWWWWWWG',
  'IIIIIIIIWWWWWWWG',
  'IIIIIIIIWWWWWWWG',
  'IGGIIGGIWWWWWWWG',
  'IIGIIGIIWWkkWWWG',
  'GIIIIIIGWWkkWWWG',
  'GGGIIGGGWWkkWWWG',
  'GGGGGGGGGGGGGGGG',
];

const INN = [
  'GGGGGGGGGGGGGGGG',
  'GGGGGTTTTTTGGGGG',
  'GGGTTTTTTTTTTGGG',
  'GGTTTTTTTTTTTTGG',
  'GTTTTTTTTTTTTTTG',
  'GWWWWWWWWWWWWWWG',
  'GWWWWWWWWWWWWWWG',
  'GWWyyWWWWWWyyWWG',
  'GWWyyWWWWWWyyWWG',
  'GWWWWWWWWWWWWWWG',
  'GWWWWoWWWWWWWWWG',
  'GWWWWyWkkkWWWWWG',
  'GWWWWWWkkkWWWWWG',
  'GWWWWWWkkkWWWWWG',
  'GWWWWWWkkkWWWWWG',
  'GGGGGGGGGGGGGGGG',
];

const FORGE = [
  'GGGGGIIGGGGGGGGG',
  'GGGGSSSSGGGGGGGG',
  'GGGGSSSSGGGGGGGG',
  'GGGGSSSSGGGGGGGG',
  'GGSSSSSSSSSSSSGG',
  'GSSSSSSSSSSSSSSG',
  'GSSSSSSSSSSSSSSG',
  'GSSSSSSSSSSSSSSG',
  'GSSrrrrSSSSSSSSG',
  'GSroyyorSSkkkSSG',
  'GSryyyyrSSkkkSSG',
  'GSryyyyrSSkkkSSG',
  'GSSSSSSSSSkkkSSG',
  'GSSSSSSSSSkkkSSG',
  'GSSSSSSSSSSSSSSG',
  'GGGGGGGGGGGGGGGG',
];

const GRAVEYARD = [
  'GGGGGGGGGGGGGGGG',
  'GGGGGGGGGGGGGGGG',
  'GGGGGGGGIGGGGGGG',
  'GGGSSSGGIGGGGGGG',
  'GGSSSSSIIIGGGGGG',
  'GGSSSSSGIGGGGGGG',
  'GGSSSSSGIGGGGGGG',
  'GGSSSSSGIGGSSSGG',
  'GGSSSSSGIGSSSSSG',
  'GGSSSSSGIGSSSSSG',
  'GGSSSSSGIGSSSSSG',
  'GGSSSSSGIGSSSSSG',
  'GGSSSSSGIGSSSSSG',
  'GEEEEEEEEEEEEEEG',
  'GEEEEEEEEEEEEEEG',
  'GGvGGGGGvGGGGvGG',
];

const MANOR = [
  'GGIIGGGGGGGGIIGG',
  'GGSSGGGGGGGGSSGG',
  'GGSSGGGGGGGGSSGG',
  'GGSSRRRRRRRRSSGG',
  'GGRRRRRRRRRRRRGG',
  'GRRRRRRRRRRRRRRG',
  'GRRRRRRRRRRRRRRG',
  'GSSSSSSSSSSSSSSG',
  'GSyySSyySSyySSSG',
  'GSyySSyySSyySSSG',
  'GSSSSSSSSSSSSSSG',
  'GSyySSSSSSSyySSG',
  'GSyySSkkkkSyySSG',
  'GSSSSSkkkkSSSSSG',
  'GSSSSSkkkkSSSSSG',
  'GGGGGGGGGGGGGGGG',
];

const WATCHTOWER = [
  'GGGGGGGyyGGGGGGG',
  'GGGGGGoyyoGGGGGG',
  'GGGSSGSSGSSGSSGG',
  'GGGSSSSSSSSSSSGG',
  'GGGGSSSSSSSSGGGG',
  'GGGGSSSSSSSSGGGG',
  'GGGGSSySSSSSGGGG',
  'GGGGSSSSSSSSGGGG',
  'GGGGSSSSSySSGGGG',
  'GGGGSSSSSSSSGGGG',
  'GGGGSSSSSSSSGGGG',
  'GGGSSSSSSSSSSGGG',
  'GGGSSSSSSSSSSGGG',
  'GGSSSSkkkSSSSSGG',
  'GGSSSSkkkSSSSSGG',
  'GGGGGGGGGGGGGGGG',
];

const WELL = [
  'GGGGGGGRRGGGGGGG',
  'GGGGGRRRRRRGGGGG',
  'GGGRRRRRRRRRRGGG',
  'GGRRRRRRRRRRRRGG',
  'GGGWGGGGWGGGWGGG',
  'GGGWGGGGdGGGWGGG',
  'GGGWGGGWWWWGWGGG',
  'GGGWGGGWWWWGWGGG',
  'GGGSSSSSSSSSSGGG',
  'GGSSkkkkkkkkSSGG',
  'GGSSkkkkkkkkSSGG',
  'GGSSkkkkkkkkSSGG',
  'GGSSSSSSSSSSSSGG',
  'GGSSSSSSSSSSSSGG',
  'GGGSSSSSSSSSSGGG',
  'GGGGGGGGGGGGGGGG',
];

// ---------------------------------------------------------------- nature

const MOUNTAIN = [
  'GGGGGGGGGGGGGGGG',
  'GGGGGGGNNGGGGGGG',
  'GGGGGGNNNNGGGGGG',
  'GGGGGNNMMNNGGGGG',
  'GGGGMMMMMMMMGGGG',
  'GGGNMMMMMMMMMGGG',
  'GGNNMMMMMMMMMMGG',
  'GMMMMMMMMMMMMMGG',
  'GMMMMMMMMMMMMMMG',
  'MMMMMMMMMMMMMMMG',
  'MMMMMMMMMMMMMMMM',
  'MMMMMMMMMMMMMMMM',
  'MMMMMMMMMMMMMMMM',
  'MMMMMMMMMMMMMMMM',
  'MMMMMMMMMMMMMMMM',
  'GGGGGGGGGGGGGGGG',
];

// The ridge running down-right from the peak, and the lit shoulder under it.
// Without these the shader gives a smooth dome; a mountain needs one hard break.
const MOUNTAIN_SHADE = [
  '................',
  '................',
  '................',
  '................',
  '.........-......',
  '.........--.....',
  '..........--....',
  '...........--...',
  '............--..',
  '.....++......--.',
  '....+++.......-.',
  '...+++..........',
  '...++...........',
  '..++............',
  '..+.............',
  '................',
];

// Two spruces, tiered so the shader separates the branches. Rows 9 and 10 run
// edge to edge: FOREST blocks line of sight (design section 5.3) and has to
// look like it does.
const FOREST = [
  'GGGGGGGGGGGFGGGG',
  'GGGFGGGGGGFFFGGG',
  'GGFFFGGGGGFFFGGG',
  'GGFFFGGGGFFFFFGG',
  'GFFFFFGGGFFFFFGG',
  'GFFFFFGGFFFFFFFG',
  'FFFFFFFGFFFFFFFG',
  'FFFFFFFGGFFFFFGG',
  'GFFFFFGGFFFFFFFG',
  'FFFFFFFFFFFFFFFF',
  'FFFFFFFFFFFFFFFF',
  'GGGWGGGFFFFFFFFF',
  'GGGWGGGGGGGWGGGG',
  'GGGWGGGGGGGWGGGG',
  'GGGGGGGGGGGWGGGG',
  'GGGGGGGGGGGGGGGG',
];

// The moon's reflection is the point of the tile: a broken column of white down
// the middle, and the only place on the board the moon itself is visible.
const LAKE_SHADE = [
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
  '-.-.-.-.-.-.-.-.',
  '.-.-.-.-.-.-.-.-',
];

const LAKE = [
  'GGGGGGGGGGGGGGGG',
  'GGGAAAAAAAAAAGGG',
  'GAAAAAAAAAAAAAAG',
  'AAAAAAAhAAAAAAAA',
  'AAAAAAAhhAAAAAAA',
  'AAAAAAAlAAAAAAAA',
  'AAAllAAhhAAAAAAA',
  'AAAAAAAlAAAAllAA',
  'AAAAAAAhhAAAAAAA',
  'AAAAAAAlAAAAAAAA',
  'AAAllAAhhAAAAAAA',
  'AAAAAAAlAAAAAAAA',
  'AAAAAAAhAAAAAAAA',
  'GAAAAAAAAAAAAAAG',
  'GGAAAAAAAAAAAAGG',
  'GGGGGGGGGGGGGGGG',
];

// ---------------------------------------------------------------- figures

// The player carries the only warm light on the board, which is how the eye
// finds them among eight villagers without spending a hue on them (design
// section 9.1). No placeholder materials: this sprite is drawn without a
// per-character pal().
const PLAYER = [
  '................',
  '.....DDDDDD.....',
  '..DDDDDDDDDDDD..',
  '....KKKKKKKK....',
  '....KuKKKKuK....',
  '....KKKKKKKK....',
  '.....DDDDDD.....',
  '....DDDDDDDD....',
  '...DDDDDDDDDD...',
  '...DDDDDDDDDDoy.',
  '...DDDDDDDDDoyy.',
  '...DDDDDDDDDDoy.',
  '...DDDDDDDDDD...',
  '...DDDD..DDDD...',
  '...DDD....DDD...',
  '................',
];

// The reveal sprite. Its fur is the cloak placeholder, so it takes the accused
// villager's own hue when they turn -- the last thing the player sees is that
// colour on the wrong body.
const WOLF = [
  '................',
  '..CC........CC..',
  '..CCC......CCC..',
  '..CCCC....CCCC..',
  '..CCCCC..CCCCC..',
  '..CCCCCCCCCCCC..',
  '.CCCCCCCCCCCCCC.',
  '.CCyCCCCCCCCyCC.',
  '.CCCCCCCCCCCCCC.',
  '.CCCCCuuuuCCCCC.',
  '..CCCCuuuuCCCC..',
  '..CCCChuuhCCCC..',
  '...CCCCCCCCCC...',
  '....CCCCCCCC....',
  '.....CCCCCC.....',
  '................',
];

// One body, eight heads: at 16 pixels the board is read by hue and by the shape
// on top of the head, not by tailoring (design section 9.1).
const BODY = [
  '................',
  '................',
  '.....KKKKKK.....',
  '....KKKKKKKK....',
  '....KuKKKKuK....',
  '....KKKKKKKK....',
  '.....KKKKKK.....',
  '...CCCCCCCCCC...',
  '..CCCCCCCCCCCC..',
  '..CCCCCCCCCCCC..',
  '..CCCCCCCCCCCC..',
  '..CCCCCCCCCCCC..',
  '..CCCCCCCCCCCC..',
  '..CCCC....CCCC..',
  '..CCC......CCC..',
  '................',
];

// The neck's shadow on the shoulders, and one fold down the cloak. The shader
// only knows about edges; a garment needs at least one crease inside it.
const BODY_SHADE = [
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '.....------.....',
  '....-......-....',
  '....-......-....',
  '....-......-....',
  '....-......-....',
  '..------------..',
  '................',
  '................',
  '................',
];

// Overlaid on BODY from row 0 down; '.' leaves the body alone.
const HATS = [
  ['......LLLL......', '.....LLLLLL.....', '....LLLLLLLL....'],                       // bela, mitre
  ['................', '....DDDDDDDD....', '...DDDDDDDDDD...', '...DD......DD...'],   // mara, headscarf
  ['................', '....DDDDDDDD....', '..DDDDDDDDDDDD..'],                       // otto, flat cap
  ['.......DD.......', '....DDDDDDDD....', '...DDDDDDDDDD...'],                       // vesna, pinned hair
  ['................', '....DDDDDDDD....', '...DDDDDDDDDD...', '....rrrrrrrr....'],   // dragan, headband
  ['................', '......DDDD......', '.DDDDDDDDDDDDDD.'],                       // luka, wide brim
  ['................', '....DDDDDDDD....', '..DDDDDDDDDDDD..', '..DD........DD..',
   '..DD........DD..', '..DD........DD..'],                                           // iris, veil
  ['................', '....SSSSSSSS....', '...SSSSSSSSSS...', '...SSSSSSSSSS...',
   '.......SS.......'],                                                               // stefan, helmet
];

function villager(i) {
  const t = BODY.slice();
  HATS[i].forEach((row, y) => {
    t[y] = [...t[y]].map((ch, x) => (row[x] === '.' ? ch : row[x])).join('');
  });
  return t;
}

// ---------------------------------------------------------------- the shader

const W = 16;

function shadeTile(art, shadeMap, figure, ground) {
  const at = (x, y) => (x < 0 || y < 0 || x >= W || y >= W) ? null : art[y][x];
  const px = Array.from({ length: W }, () => new Array(W).fill(-1));

  for (let y = 0; y < W; y++) {
    for (let x = 0; x < W; x++) {
      const c = art[y][x];
      if (c === '.') continue;                       // transparent, figures only
      if (c === 'G') { px[y][x] = ground[y][x]; continue; }
      if (LIT[c] !== undefined) { px[y][x] = LIT[c]; continue; }
      const ramp = MAT[c];
      if (!ramp) throw new Error('unknown material "' + c + '"');

      let t;
      if (at(x, y - 1) !== c || at(x - 1, y) !== c) t = 0;
      else if (at(x, y + 1) !== c || at(x + 1, y) !== c) t = 2;
      else if (((x + y) & 1) === 0 && (at(x, y + 2) !== c || at(x + 2, y) !== c)) t = 2;
      else t = 1;

      const s = shadeMap && shadeMap[y] ? shadeMap[y][x] : '.';
      if (s === '-') t = Math.min(2, t + 1);
      if (s === '+') t = Math.max(0, t - 1);
      px[y][x] = ramp[t];
    }
  }

  // lamplight: cold stone warms where a lit window touches it
  const WARM = { 1: 5, 5: 9, 6: 7, 4: 9, 2: 4 };
  const shaded = (x, y) => LIT[art[y][x]] === undefined && art[y][x] !== '.' && art[y][x] !== 'G';
  const warmed = [];
  for (let y = 0; y < W; y++) {
    for (let x = 0; x < W; x++) {
      if (px[y][x] !== 10) continue;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= W || ny >= W) continue;
        if (!shaded(nx, ny)) continue;
        if (WARM[px[ny][nx]] !== undefined) warmed.push([nx, ny, WARM[px[ny][nx]]]);
      }
    }
  }
  for (const [x, y, c] of warmed) px[y][x] = c;

  const opaque = (x, y, ch) =>
    x >= 0 && y >= 0 && x < W && y < W && art[y][x] !== ch;

  if (figure) {
    // outline in the state placeholder: the cart maps it to 0 unvisited,
    // 5 already heard, 8 accused (design section 9.1)
    const rim = [];
    for (let y = 0; y < W; y++) {
      for (let x = 0; x < W; x++) {
        if (art[y][x] !== '.') continue;
        let touch = false;
        for (let dy = -1; dy <= 1 && !touch; dy++) {
          for (let dx = -1; dx <= 1 && !touch; dx++) {
            if (opaque(x + dx, y + dy, '.')) touch = true;
          }
        }
        if (touch) rim.push([x, y]);
      }
    }
    for (const [x, y] of rim) px[y][x] = OUTLINE;
  } else {
    // contact shadow: nothing floats
    const cast = [];
    for (let y = 0; y < W; y++) {
      for (let x = 0; x < W; x++) {
        if (art[y][x] !== 'G') continue;
        if (opaque(x - 1, y - 1, 'G')) cast.push([x, y]);
        else if (opaque(x - 2, y - 2, 'G') && ((x + y) & 1) === 0) cast.push([x, y]);
      }
    }
    for (const [x, y] of cast) px[y][x] = 0;
  }

  return px;
}

// ---------------------------------------------------------------- the ui set

// Sprite row 6 (sprites 96+), in 8x8 pieces: the furniture the panels are
// built from. These are hand-coloured rather than shaded, and deliberately so
// -- the shader lights a *surface* by which way it faces, and a cast brass
// boss 6 pixels across has no surfaces, only a curve. What keeps it in the
// same world as the buildings is the ramp it is drawn from: y/o/w is the
// thatch ramp (10,9,4) with 2 underneath it, i.e. lamplight on metal, lit
// from up and to the left like everything else on the sheet.
//
// The frame's straight runs are not art. A moulding's cross-section is
// constant along an edge, so the cart draws the edges as five lines and only
// the corners come from here -- which is also why the boss has to be
// symmetric: one sprite serves all four corners, unflipped.
const UI = {
  // 96: the corner rivet. Five pixels square, because the moulding it caps is
  // three and every screen's text was laid out against a two-pixel box -- a
  // boss any fatter would start eating first characters. Ringed in 2 rather
  // than black: 0 is transparency here, so the ring has to be a colour, and
  // 2 is what the brass ramp bottoms out at anyway.
  boss: [
    'uuuuu...',
    'uyowu...',
    'uorwu...',
    'uwwuu...',
    'uuuuu...',
    '........',
    '........',
    '........',
  ],
  // 97: the menu cursor. Widths 2,3,4,5,4,3,2 with a dark spine down the
  // back, so it reads as a cast arrowhead seen edge-on rather than a filled
  // triangle. Drawn one pixel above the text baseline puts the tip on it.
  cursor: [
    'wy......',
    'wyy.....',
    'wyyo....',
    'wyoow...',
    'wyow....',
    'wow.....',
    'ww......',
    '........',
  ],
  // 98: the dialogue's continue chevron, blinked once the line has finished
  // typing -- it points down, at the button about to be pressed.
  chevron: [
    'yyyyoww.',
    '.yyoow..',
    '..yow...',
    '...o....',
    '........',
    '........',
    '........',
    '........',
  ],
  // 99: the gem that breaks a divider rule in half, and sits on the hud rail.
  gem: [
    '..y.....',
    '.yoo....',
    'yooww...',
    '.oww....',
    '..w.....',
    '........',
    '........',
    '........',
  ],
};

const UI_ORDER = ['boss', 'cursor', 'chevron', 'gem'];

// ---------------------------------------------------------------- assembly

const TILES = [
  ...[0, 1, 2, 3, 4, 5, 6, 7].map(i => ({
    art: villager(i), shade: BODY_SHADE, tx: i, ty: 0, figure: true,
  })),
  ...[CHAPEL, MILL, INN, FORGE, GRAVEYARD, MANOR, WATCHTOWER, WELL]
    .map((art, i) => ({ art, tx: i, ty: 1 })),
  { art: MOUNTAIN, shade: MOUNTAIN_SHADE, tx: 0, ty: 2 },
  { art: FOREST, tx: 1, ty: 2 },
  { art: LAKE, shade: LAKE_SHADE, tx: 2, ty: 2 },
  { art: GROUND, tx: 3, ty: 2 },
  { art: PLAYER, tx: 4, ty: 2, figure: true },
  { art: WOLF, tx: 5, ty: 2, figure: true },
];

function buildGfx() {
  const H = 56;                       // three tile rows of art, then the ui row
  const px = Array.from({ length: H }, () => new Array(128).fill(0));

  const ground = shadeTile(GROUND, null, false, null);

  for (const t of TILES) {
    const where = 'tile ' + t.tx + ',' + t.ty;
    if (t.art.length !== W) throw new Error(where + ': ' + t.art.length + ' rows');
    t.art.forEach((row, y) => {
      if (row.length !== W) {
        throw new Error(where + ' row ' + y + ': ' + row.length + ' chars "' + row + '"');
      }
      // a board tile that leaks a transparent pixel would punch a hole in the
      // board, because landmarks are blitted opaque over the ground
      if (!t.figure && row.includes('.')) {
        throw new Error('board ' + where + ' row ' + y + ' has a transparent pixel');
      }
      if (t.figure && row.includes('G')) {
        throw new Error('figure ' + where + ' row ' + y + ' uses the ground passthrough');
      }
    });

    const tile = shadeTile(t.art, t.shade, t.figure, ground);

    for (let y = 0; y < W; y++) {
      for (let x = 0; x < W; x++) {
        const c = tile[y][x];
        if (c < 0) continue;                        // transparent
        // The cart re-maps 3/11/12/13 on every figure it draws. A figure pixel
        // carrying one of those for any reason other than cloak-or-outline would
        // change colour with the speaker, which is the bug this check exists to
        // make impossible.
        if (t.figure && RESERVED.includes(c) && t.art[y][x] !== 'C' && t.art[y][x] !== '.') {
          throw new Error(where + ' (' + x + ',' + y + '): colour ' + c + ' is reserved on figures');
        }
        px[t.ty * 16 + y][t.tx * 16 + x] = c;
      }
    }
  }

  // the ui row: 8x8 pieces along sprite row 6
  UI_ORDER.forEach((name, i) => {
    const art = UI[name];
    if (art.length !== 8) throw new Error('ui ' + name + ': ' + art.length + ' rows');
    art.forEach((row, y) => {
      if (row.length !== 8) throw new Error('ui ' + name + ' row ' + y + ': ' + row.length);
      for (let x = 0; x < 8; x++) {
        const ch = row[x];
        if (ch === '.') continue;
        if (LIT[ch] === undefined) throw new Error('ui ' + name + ': unknown colour "' + ch + '"');
        px[48 + y][i * 8 + x] = LIT[ch];
      }
    });
  });

  return px.map(row => {
    const line = row.map(v => v.toString(16)).join('');
    if (line.length !== 128) throw new Error('gfx line width ' + line.length);
    return line;
  }).join('\n');
}

module.exports = { buildGfx, HUE, HHI, HLO };

if (require.main === module) {
  const gfx = buildGfx();
  console.log(gfx.split('\n').length + ' gfx lines, all 128 wide');
  const shade = ' .:-=+*#%@ABCDEF';
  gfx.split('\n').forEach(l => console.log([...l].map(h => shade[parseInt(h, 16)]).join('')));
}
