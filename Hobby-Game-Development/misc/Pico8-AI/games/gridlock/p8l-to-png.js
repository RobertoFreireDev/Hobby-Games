const fs = require('fs'), zlib = require('zlib');
const PAL = ['000000','1d2b53','7e2553','008751','ab5236','5f574f','c2c3c7','fff1e8',
             'ff004d','ffa300','ffec27','00e436','29adff','83769c','ff77a8','ffccaa'];
const SC = 3;
function crc(b){let c=~0;for(const x of b){c^=x;for(let k=0;k<8;k++)c=(c>>>1)^(0xEDB88320&-(c&1));}return ~c>>>0;}
function chunk(t,d){const l=Buffer.alloc(4);l.writeUInt32BE(d.length);const b=Buffer.concat([Buffer.from(t),d]);const c=Buffer.alloc(4);c.writeUInt32BE(crc(b));return Buffer.concat([l,b,c]);}
for (const f of process.argv.slice(2)) {
  const rows = fs.readFileSync(f,'utf8').split('\n').map(l=>l.trim()).filter(l=>l.length===128);
  if (rows.length !== 128) throw new Error(f+' has '+rows.length+' rows');
  const W = 128*SC, raw = Buffer.alloc((W*3+1)*W);
  let o=0;
  for (let y=0;y<W;y++){ raw[o++]=0;
    for (let x=0;x<W;x++){ const h=PAL[parseInt(rows[(y/SC)|0][(x/SC)|0],16)];
      raw[o++]=parseInt(h.slice(0,2),16); raw[o++]=parseInt(h.slice(2,4),16); raw[o++]=parseInt(h.slice(4,6),16); } }
  const ihdr=Buffer.alloc(13); ihdr.writeUInt32BE(W,0); ihdr.writeUInt32BE(W,4); ihdr[8]=8; ihdr[9]=2;
  const png=Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',ihdr),chunk('IDAT',zlib.deflateSync(raw)),chunk('IEND',Buffer.alloc(0))]);
  const out=f.replace('.p8l','.png');
  fs.writeFileSync(out,png); console.log('wrote '+out);
}
