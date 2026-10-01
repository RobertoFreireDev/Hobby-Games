// decode/encode the __map__ section of stackrunner's cart into 16 10x9 level grids
const fs=require('fs');
const MCHR="#o-=^2abcdxyp";
const BW=10,BH=9,NLV=16;

function readCart(p){return fs.readFileSync(p,'utf8').split(/\r?\n/);}

function mapRows(lines){
  const i=lines.indexOf('__map__');
  const rows=[];
  for(let k=i+1;k<lines.length;k++){
    const l=lines[k];
    if(l.startsWith('__'))break;
    rows.push(l);
  }
  return {start:i+1,rows};
}

function decode(path){
  const lines=readCart(path);
  const {rows}=mapRows(lines);
  const grid=[]; // 128x64 tile values
  for(let y=0;y<rows.length;y++){
    grid[y]=[];
    for(let x=0;x<128;x++){
      grid[y][x]=parseInt(rows[y].substr(x*2,2),16)||0;
    }
  }
  const levels=[];
  for(let n=1;n<=NLV;n++){
    const ox=((n-1)%8)*16, oy=Math.floor((n-1)/8)*16;
    const lv=[];
    for(let y=0;y<BH;y++){
      let s='';
      for(let x=0;x<BW;x++){
        const v=(grid[oy+y]||[])[ox+x]||0;
        s+= v>0? MCHR[v-48] : '.';
      }
      lv.push(s);
    }
    levels.push(lv);
  }
  return levels;
}

function encode(path,levels){
  const lines=readCart(path);
  const {start,rows}=mapRows(lines);
  const grid=[];
  for(let y=0;y<rows.length;y++){
    grid[y]=[];
    for(let x=0;x<128;x++) grid[y][x]=parseInt(rows[y].substr(x*2,2),16)||0;
  }
  for(let n=1;n<=NLV;n++){
    const ox=((n-1)%8)*16, oy=Math.floor((n-1)/8)*16;
    const lv=levels[n-1];
    for(let y=0;y<BH;y++){
      for(let x=0;x<BW;x++){
        const c=lv[y][x];
        grid[oy+y][ox+x]= c==='.'?0:(MCHR.indexOf(c)+48);
      }
    }
  }
  for(let y=0;y<rows.length;y++){
    let s='';
    for(let x=0;x<128;x++) s+=grid[y][x].toString(16).padStart(2,'0');
    lines[start+y]=s;
  }
  fs.writeFileSync(path,lines.join('\n'));
}

module.exports={decode,encode,BW,BH,NLV,MCHR};

if(require.main===module){
  const levels=decode(process.argv[2]);
  levels.forEach((l,i)=>{console.log('-- floor '+(i+1));l.forEach(r=>console.log(r));});
}
