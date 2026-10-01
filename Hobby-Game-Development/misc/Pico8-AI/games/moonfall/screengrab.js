// screengrab.js -- render chosen screens through the real engine and save PNGs
//
//   node screengrab.js
//
// A layout is only verified once it has been looked at. This appends a small
// driver to game.p8 that draws a screen, dumps 0x6000 over printh, and writes
// each frame out as a 2x png.

'use strict';
const fs = require('fs');
const { spawnSync } = require('child_process');
const PICO8 = 'C:/Program Files (x86)/PICO-8/pico8.exe';
const TEST = '_shot.p8';

const driver = `
-->8
function _init() end
function _update60() end
function _draw() end
function shot(name)
 local o=""
 for a=0x6000,0x7fff do
  local b=peek(a)
  o=o..sub("0123456789abcdef",(b&15)+1,(b&15)+1)
       ..sub("0123456789abcdef",(b>>4)+1,(b>>4)+1)
  if #o>=256 then printh("PX "..o) o="" end
 end
 printh("SHOT "..name)
end
cartdata("moonfall_rf1")
nm=split"bela,mara,otto,vesna,dragan,luka,iris,stefan"
lmn=split"CHAPEL,MILL,INN,FORGE,GRAVEYARD,MANOR,WATCHTOWER,WELL,MOUNTAIN,FOREST,LAKE"
hue=split"7,3,4,9,8,5,2,12"
hhi=split"7,11,9,10,14,6,13,6"
hlo=split"5,1,2,4,2,1,1,1"
plt=split(pltd,"|",false)
wit=split(witd,"|",false)
sgn=split(sgnd,"|",false)
rmps=split(rmpd,"|",false)
night=1 fr=0 it=0
loadnight(1)
scr=6
-- partial knowledge first: what the notebook looks like mid-night
for v=1,5 do heard[v]=true end
nheard=5
npage=1 dwnote() shot("claims-partial")
dsel=3 npage=3 dwnote() shot("details-partial")
for v=1,8 do heard[v]=true end
nheard=8
npage=1 dwnote() shot("claims")
npage=2 dwnote() shot("sightings")
npage=3 dwnote() shot("details")
dsel=7 npage=3 dwnote() shot("details-2")
npage=4 dwnote() shot("village")
npage=5 dwnote() shot("wild")
npage=6 dwnote() shot("eight")
scr=2 hpage=5 dwhow() shot("howto-eight")
scr=6
-- the darkest nightfall ramp, baked into the buffer: the notebook is read
-- late, and low-contrast banding would fail exactly then
function ramp()
 local r=rmps[5]
 for a=0x6000,0x7fff do
  local b=peek(a)
  poke(a,d32(r,(b&15)+1)|(d32(r,(b>>4)+1)<<4))
 end
end
npage=3 dwnote() ramp() shot("details-night")
npage=1 dwnote() ramp() shot("claims-night")
loadnight(9)
for v=1,8 do heard[v]=true end
nheard=8
npage=2 dwnote() shot("sightings-n9")
dsel=1 npage=3 dwnote() shot("details-n9")
scr=7 ai=3 confirm=false
for v=1,8 do heard[v]=(v%2==1) end
dwboard() dwacc() shot("accuse")
dwboard() confirm=true dwacc() shot("accuse-confirm")

-- the title screen at its settled frame, with the menu over it
loadnight(1)
scr=1 mi=1 it=560 fr=0
dwintro() dwmenu() shot("menu")
mi=2 dwintro() dwmenu() shot("menu-2")

-- the board and its hud, at noon and again with the moon nearly up
scr=4 tk=12 dwboard() dwhud() shot("board")
tk=36 dwboard() dwhud() shot("board-late")

-- the briefing
scr=3 dwboard() dwbrief() shot("brief")

-- dialogue: mid-type, and finished with the chevron showing
scr=5 tk=6
opendlg(4)
dtick=28 dwboard() dwdlg() shot("dialog-typing")
dtick=dtotal*2 fr=0 dwboard() dwdlg() shot("dialog")
setpage(2) dtick=dtotal*2 dwboard() dwdlg() shot("dialog-p2")

-- the legend, which is the page with the tightest right margin
scr=2 hpage=1 dwhow() shot("how-1")
hpage=3 dwhow() shot("how-3")
hpage=5 dwhow() shot("how-5")

-- both verdicts
scr=8 it=100
guilty=wolf dwverd() shot("verdict-win")
guilty=(wolf%8)+1 dwverd() shot("verdict-lose")
extcmd("shutdown")
`;

const cart = fs.readFileSync('game.p8', 'utf8');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
fs.writeFileSync(TEST, cart.slice(0, i) + driver + '\n' + cart.slice(i));

const r = spawnSync(PICO8, ['-x', TEST], { encoding: 'utf8', timeout: 120000, maxBuffer: 1 << 28 });
fs.unlinkSync(TEST);
const out = ((r.stdout || '') + (r.stderr || '')).split('\n')
  .map(l => l.replace(/^INFO:\s?/, '').trim());

const PAL = ['000000','1D2B53','7E2553','008751','AB5236','5F574F','C2C3C7','FFF1E8',
             'FF004D','FFA300','FFEC27','00E436','29ADFF','83769C','FF77A8','FFCCAA'];
const zlib = require('zlib');
function crc32(buf, T = crc32.T) {
  if (!T) { T = crc32.T = []; for (let n = 0; n < 256; n++) { let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; T[n] = c; } }
  let c = 0xFFFFFFFF;
  for (const b of buf) c = T[(c ^ b) & 0xFF] ^ (c >>> 8);
  return (c ^ 0xFFFFFFFF) >>> 0;
}
function png(grid, file, scale) {
  const H = grid.length, W = grid[0].length, PW = W * scale, PH = H * scale;
  const raw = Buffer.alloc((PW * 3 + 1) * PH);
  let p = 0;
  for (let y = 0; y < PH; y++) {
    raw[p++] = 0;
    for (let x = 0; x < PW; x++) {
      const rgb = PAL[grid[(y / scale) | 0][(x / scale) | 0]];
      raw[p++] = parseInt(rgb.slice(0, 2), 16);
      raw[p++] = parseInt(rgb.slice(2, 4), 16);
      raw[p++] = parseInt(rgb.slice(4, 6), 16);
    }
  }
  const chunk = (t, d) => {
    const l = Buffer.alloc(4); l.writeUInt32BE(d.length);
    const b = Buffer.concat([Buffer.from(t, 'ascii'), d]);
    const c = Buffer.alloc(4); c.writeUInt32BE(crc32(b));
    return Buffer.concat([l, b, c]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(PW, 0); ihdr.writeUInt32BE(PH, 4); ihdr[8] = 8; ihdr[9] = 2;
  fs.writeFileSync(file, Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

let px = '';
let n = 0;
for (const l of out) {
  if (l.startsWith('PX ')) px += l.slice(3);
  else if (l.startsWith('SHOT ')) {
    const name = l.slice(5);
    if (px.length < 128 * 128) { console.log('short frame', name, px.length); px = ''; continue; }
    const grid = [];
    for (let y = 0; y < 128; y++) {
      const row = [];
      for (let x = 0; x < 128; x++) row.push(parseInt(px[y * 128 + x], 16));
      grid.push(row);
    }
    png(grid, 'shot-' + name + '.png', 3);
    console.log('wrote shot-' + name + '.png');
    px = ''; n++;
  }
}
if (!n) { console.log(out.filter(Boolean).slice(-20).join('\n')); process.exit(1); }
