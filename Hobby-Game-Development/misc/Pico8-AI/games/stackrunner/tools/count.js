// how many complete runs through all sixteen floors exist, bounded so it terminates
const L=require('./levels'); const A=require('./analyze');
const floors=L.load(process.argv[2]||'tools/levels3.txt');
const CAP=+(process.env.CAP||40000), BUDGET=+(process.env.BUDGET||4000);
const cache=new Map(); const memo=new Map(); let used=0, hitBudget=false;
function hauls(n,h){
  const k=n+'|'+h;
  if(cache.has(k))return cache.get(k);
  if(used>=BUDGET){hitBudget=true;return [];}
  used++;
  const [m,i]=h.split('/');
  const r=A.analyze(floors[n-1],m.split('').filter(Boolean),(i||'').split('').filter(Boolean),{cap:CAP});
  const out=r.solvable?[...r.hauls.keys()]:null;
  cache.set(k,out); return out;
}
function chains(n,h){
  const k=n+'|'+h;
  if(memo.has(k))return memo.get(k);
  memo.set(k,0);
  const hs=hauls(n,h);
  if(!hs) {memo.set(k,0);return 0;}
  if(n===floors.length){memo.set(k,1);return 1;}
  let t=0;
  for(const e of hs){ t+=chains(n+1,e); if(t>1e9)break; }
  memo.set(k,t); return t;
}
const t=chains(1,(process.env.START||'bcb')+'/');
console.log('complete runs through all '+floors.length+' floors: '+t+(hitBudget?' (analysis budget hit - lower bound)':''));
console.log('floor/stack pairs analysed: '+used);
