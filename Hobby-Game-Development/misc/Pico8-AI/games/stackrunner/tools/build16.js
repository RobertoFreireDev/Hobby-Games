const G=require('./gen'); const S=require('./search'); const L=require('./levels');
const cfgs=require('./floorcfg'); const fs=require('fs');
const outFile=process.env.OUT||'tools/levels.txt';
let mv=process.env.START||'bcb', it='';
const out=[];
for(let n=1;n<=16;n++){
  const cfg=Object.assign({},cfgs[n-1]);
  const b=G.generate(mv,it,cfg);
  if(!b||!b.e){console.log('floor '+n+' FAILED from '+mv+'/'+it);break;}
  out.push(b.rows);
  S.show(b,'floor '+n+'  entry '+mv+'/'+it);
  const hs=b.e.hauls.slice().sort((x,y)=>y.split('/')[0].length-x.split('/')[0].length);
  console.log('  hauls: '+hs.join(' '));
  [mv,it]=hs[0].split('/');
  console.log('  -> entry '+mv+'/'+(it||'-'));
  L.save(outFile,out);
}
L.save(outFile,out);
console.log('saved '+outFile);
