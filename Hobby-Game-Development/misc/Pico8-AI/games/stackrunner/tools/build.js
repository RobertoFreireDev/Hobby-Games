const S=require('./search'); const L=require('./levels'); const spec=require('./spec');
const A=require('./analyze');
const only=process.argv[2]?process.argv[2].split(',').map(Number):null;
const fs=require('fs');
let cur=null;
try{cur=L.load('tools/levels.txt');}catch(e){}
const out=cur&&cur.length===16?cur.slice():[];
let mv=process.env.START||'bcb',it='';
for(let n=1;n<=16;n++){
  const f=spec[n-1];
  if(only&&!only.includes(n)){
    // keep existing floor, just advance the haul
    const e=S.evaluate(out[n-1],mv,it,{cap:200000});
    if(!e){console.log('floor',n,'UNSOLVABLE from',mv+'/'+it);break;}
    const best=e.hauls.slice().sort((a,b)=>b.split('/')[0].length-a.split('/')[0].length)[0];
    console.log(`floor ${n} kept  entry ${mv}/${it} -> ${best}  free=${e.freePct.toFixed(0)}% routes=${e.routes} bad=${e.bad}/${e.near.length}`);
    [mv,it]=best.split('/'); continue;
  }
  const cfg=Object.assign({cap:60000},f.cfg);
  const b=S.search(f.tpl,f.pool,mv,it,cfg);
  if(!b||!b.e){console.log('floor '+n+' NO SOLVABLE LAYOUT from '+mv+'/'+it);break;}
  out[n-1]=b.rows;
  S.show(b,'floor '+n+'  entry '+mv+'/'+it);
  const best=b.e.hauls.slice().sort((a,b2)=>b2.split('/')[0].length-a.split('/')[0].length)[0];
  console.log('  -> next entry '+best);
  [mv,it]=best.split('/');
}
L.save('tools/levels.txt',out);
console.log('saved tools/levels.txt');
