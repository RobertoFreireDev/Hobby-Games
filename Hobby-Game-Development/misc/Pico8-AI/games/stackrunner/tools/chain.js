const A=require('./analyze');
const CAPCHAIN=200000;
// floors: array of 16 grids. start haul.
function run(floors,startMv,startIt,opt={}){
  const memo=new Map(); // "n|mv/it" -> {chains, ok}
  const cache=new Map();
  function floorRes(n,h){
    const k=n+'|'+h;
    if(cache.has(k))return cache.get(k);
    const [mv,it]=h.split('/');
    const a=A.analyze(floors[n-1],mv.split('').filter(Boolean),it.split('').filter(Boolean),{cap:opt.cap||300000});
    const r={hauls:new Map([...a.hauls.keys()].map(h=>[h,1])),solvable:a.solvable,
             states:a.states,traps:a.traps,deathReachable:a.deathReachable,wins:a.wins.length};
    cache.set(k,r); return r;
  }
  let calls=0;
  function chains(n,h){
    if(n>floors.length) return 1;
    const k=n+'|'+h;
    if(memo.has(k))return memo.get(k);
    memo.set(k,0); // cycle guard
    if(++calls>CAPCHAIN) return 0;
    const r=floorRes(n,h);
    // the last floor ends the run: what you leave with no longer matters
    if(n===floors.length){ const t=r.solvable?1:0; memo.set(k,t); return t; }
    let tot=0;
    for(const eh of r.hauls.keys()){
      tot+=chains(n+1,eh);
      if(tot>1000000)break;
    }
    memo.set(k,tot);
    return tot;
  }
  const total=chains(1,startMv+'/'+startIt);
  return {total,memo,cache,chains,floorRes};
}
module.exports={run};
