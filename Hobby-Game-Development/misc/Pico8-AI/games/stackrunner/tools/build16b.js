// second pass: rebuild the chain so that exactly one exit haul per floor
// can win the next floor (unique whole-game combination).
const G=require('./gen'); const S=require('./search'); const L=require('./levels');
const cfgs=require('./floorcfg');
const outFile=process.env.OUT||'tools/levels2.txt';
const seed=(()=>{try{return L.load(process.env.SEED||'tools/levels.txt');}catch(e){return null;}})();
const FROM=+(process.env.FROM||1);
let mv=process.env.START||'bcb', it='', forbid=[];
const sz=h=>{const [m,i]=h.split('/');return m.length*2+(i||'').length;};
const out=[];
for(let n=1;n<=16;n++){
  if(n<FROM){
    const keep=seed&&seed[n-1];
    if(!keep){console.log('no seed for floor '+n);break;}
    out.push(keep);
    const e=S.evaluate(keep,mv,it,{cap:200000});
    if(!e){console.log('seed floor '+n+' unsolvable from '+mv+'/'+it);break;}
    const hs2=e.hauls.filter(h=>h.split('/')[0].length>=2).sort((x,y)=>sz(y)-sz(x));
    [mv,it]=hs2[0].split('/');
    console.log('floor '+n+' kept -> '+mv+'/'+(it||'-'));
    continue;
  }
  const cfg=Object.assign({},cfgs[n-1],{forbid:process.env.NOFORBID?[]:forbid});
  // relax ladder: a floor with six pieces on it can simply fail to place,
  // so fall back to looser targets rather than breaking the chain
  const ladder=[cfg,
    Object.assign({},cfg,{freeMin:Math.max(30,(cfg.freeMin||65)-25),free4Min:45,routes:2,minDist:6}),
    Object.assign({},cfg,{freeMin:25,free4Min:30,routes:2,minDist:6,maxStraight:5,minHaul:3,minLen:5,ms:120000})];
  let b=null;
  for(const c2 of ladder){ b=G.generate(mv,it,c2); if(b&&b.e&&b.s>-500)break; }
  if((!b||!b.e||b.s<0) && seed && seed[n-1]){
    const alt=G.scoreLevel(seed[n-1],mv,it,cfg);
    if(alt.e && (!b||!b.e||alt.s>b.s)) b={rows:seed[n-1],e:alt.e,s:alt.s,sc:alt.s};
  }
  if(!b||!b.e){console.log('floor '+n+' FAILED from '+mv+'/'+it);break;}
  out.push(b.rows);
  S.show(b,'floor '+n+'  entry '+mv+'/'+(it||'-')+'  forbid=['+forbid.join(' ')+']');
  const hs=b.e.hauls.slice().filter(h=>h.split('/')[0].length>=2).sort((x,y)=>sz(y)-sz(x));
  if(!hs.length){console.log('floor '+n+' leaves nothing usable');break;}
  const top=hs[0], topN=sz(top);
  forbid=hs.slice(1).filter(h=>sz(h)>=topN-2).slice(0,8);
  [mv,it]=top.split('/');
  console.log('  -> entry '+mv+'/'+(it||'-')+'   forbid next: '+forbid.join(' '));
  L.save(outFile,out);
}
L.save(outFile,out);
console.log('saved '+outFile);
