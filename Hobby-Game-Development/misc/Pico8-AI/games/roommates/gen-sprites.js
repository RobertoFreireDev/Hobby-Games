// regenerates the 4 character sprites (2 frames x happy/mad) in game.p8's __gfx__.
// gbc-overworld style: 16x16, 3 colours + transparency, thick outline.
// legend  . transparent   o outline(1)   b body/type hue(3)   h highlight/skin(4)
const fs=require('fs');

const bodyA=[
"...oobbbbbboo...",
"..ohbbbbbbbbho..",
"..ohbbbbbbbbho..",
"...obbbbbbbbo...",
"...obboooobbo...",
"....oo....oo....",
];
const bodyB=[
"..ohoobbbbooho..",
"..ohbbbbbbbbho..",
"...obbbbbbbbo...",
"...obbbbbbbbo...",
"...oboobboobo...",
".....oo..oo.....",
];
// clinger reaches out, so it gets its own arms
const armsA=[
"...oobbbbbboo...",
"ohhoobbbbbboohho",
"...obbbbbbbbo...",
"...obbbbbbbbo...",
"...obboooobbo...",
"....oo....oo....",
];
const armsB=[
"ohhoobbbbbboohho",
"...oobbbbbboo...",
"...obbbbbbbbo...",
"...obbbbbbbbo...",
"...oboobboobo...",
".....oo..oo.....",
];

// heads, rows 0..9
const heads=[
// 1 drifter - cap with a brim
[
"................",
"....oooooooo....",
"...obbbbbbbbo...",
"..obbbbbbbbbbo..",
".oobbbbbbbbbboo.",
"..ohhhhhhhhhho..",
"..ohoohhhhooho..",
"..ohhhhhhhhhho..",
"..ohhhhoohhhho..",
"...ohhhhhhhho...",
],
// 2 homebody - hair bun, hair framing the face
[
"......oooo......",
"....oobbbboo....",
"...obbbbbbbbo...",
"..obbbbbbbbbbo..",
"..obbhhhhhhbbo..",
"..obhhhhhhhhbo..",
"..obhoohhoohbo..",
"..obhhhhhhhhbo..",
"..obhhhoohhhbo..",
"...ohhhhhhhho...",
],
// 3 loner - hood up, face in shadow
[
"................",
"....oooooooo....",
"...obbbbbbbbo...",
"..obbbbbbbbbbo..",
"..obbbbbbbbbbo..",
"..obbhhhhhhbbo..",
"..obbohhhhobbo..",
"..obbhhhhhhbbo..",
"..obbbhhhhbbbo..",
"...obbbbbbbbo...",
],
// 4 clinger - hair tuft, eager grin
[
".......oo.......",
"......obbo......",
"...oooooooooo...",
"..obbbbbbbbbbo..",
"..ohhhhhhhhhho..",
"..ohhhhhhhhhho..",
"..ohoohhhhooho..",
"..ohhhhhhhhhho..",
"..ohhhhoohhhho..",
"...ohhhhhhhho...",
],
];

// mad: brows slant in over the eyes, mouth turns down
const mad=[
{5:"..ohohhhhhhoho..",6:"..ohhohhhhohho..",8:"..ohhhoooohhho.."},
{5:"..obohhhhhhobo..",8:"..obhhoooohhbo.."},
{5:"..obbohhhhobbo..",6:"..obbhohhohbbo..",8:"..obbboooobbbo.."},
{5:"..ohohhhhhhoho..",6:"..ohhohhhhohho..",8:"..ohhhoooohhho.."},
];

const map={'.':0,'o':1,'b':3,'h':4};
const sheet=[];
for(let y=0;y<32;y++) sheet.push(new Array(128).fill(0));

function blit(cells,ox,oy){
 cells.forEach((row,y)=>{
  if(row.length!==16) throw new Error('bad row width '+row.length+' "'+row+'"');
  for(let x=0;x<16;x++){
   const c=map[row[x]];
   if(c===undefined) throw new Error('bad char '+row[x]);
   sheet[oy+y][ox+x]=c;
  }
 });
}

for(let t=0;t<4;t++){
 for(let m=0;m<2;m++){
  for(let f=0;f<2;f++){
   let head=heads[t].slice();
   if(m) for(const [r,s] of Object.entries(mad[t])) head[r]=s;
   const body=t===3?(f?armsB:armsA):(f?bodyB:bodyA);
   blit(head.concat(body),t*32+f*16,m*16);
  }
 }
}

const lines=sheet.map(r=>r.map(c=>c.toString(16)).join(''));
const src=fs.readFileSync('game.p8','utf8').split('\n');
const g=src.indexOf('__gfx__');
for(let i=0;i<32;i++) src[g+1+i]=lines[i];
fs.writeFileSync('game.p8',src.join('\n'));
console.log('wrote 32 gfx rows');
