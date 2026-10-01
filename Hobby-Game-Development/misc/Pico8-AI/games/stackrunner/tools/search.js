// random card-placement search over a wall skeleton.
// template: 9 rows of 10 chars; '?' = candidate slot filled from the pool.
const R=require('./rules'); const A=require('./analyze');
const M={'<':0,'>':1,'^':2,'v':3,'X':4};

function replay(rows,mv,it,line){
  let s=R.start(rows,mv.split('').filter(Boolean),it.split('').filter(Boolean));
  const pos=[[s.px,s.py]];
  for(const ch of line){ const r=R.apply(s,M[ch]); if(!r.s) return null; s=r.s; pos.push([s.px,s.py]); }
  return {s,pos:pos.map(p=>p.join(',')).join(' ')};
}

function evaluate(rows,mv,it,cfg={}){
  const r=A.analyze(rows,mv.split('').filter(Boolean),it.split('').filter(Boolean),{cap:cfg.cap||120000});
  if(!r.solvable) return null;
  const sols=A.solutions(r,200);
  const uniq=[...new Set(sols.map(s=>s.line))];
  const shortest=uniq[0].length;
  const near=uniq.filter(l=>l.length<=shortest+2).slice(0,40);
  const routes=new Set();
  for(const l of near){ const p=replay(rows,mv,it,l); if(p) routes.add(p.pos); }
  const bad=near.filter(l=>A.maxRun(l)>2).length;
  // freedom: of the states you can blunder into early, how many are still winnable
  const horizon=shortest+2;
  let early=0, earlyAlive=0;
  for(const [k,n] of r.seen){ if(n.d<=horizon){ early++; if(r.alive.has(k))earlyAlive++; } }
  const freePct=100*earlyAlive/early;
  const hauls=[...r.hauls.keys()];
  const bestHaul=Math.max(...hauls.map(h=>h.split('/')[0].length));
  // the line the chain actually takes: the shortest win that leaves with the richest haul
  const sz=h=>{const [m,i]=h.split('/');return m.length*2+(i||'').length;};
  const top=hauls.slice().sort((p,q)=>sz(q)-sz(p))[0];
  const topWins=r.hauls.get(top).slice().sort((p,q)=>r.seen.get(p).d-r.seen.get(q).d);
  let topLine=null;
  for(const w of topWins.slice(0,12)){ const l=A.lineFor(r,w); if(l&&(!topLine||A.maxRun(l)<A.maxRun(topLine))) topLine=l; }
  const topRun=topLine?A.maxRun(topLine):9;
  return {r,uniq,near,routes:routes.size,bad,badFrac:near.length?bad/near.length:1,
          trapPct:100*r.traps/r.states,freePct,shortest,hauls,bestHaul,topRun,topLine,
          states:r.states,death:r.deathReachable,early};
}

function score(e,cfg){
  if(!e) return -1e9;
  let s=0;
  s-= e.badFrac*500;
  s-= Math.max(0,(cfg.freeMin||60)-e.freePct)*8;
  s+= Math.min(e.routes,12)*15;
  if(e.routes<(cfg.routes||2)) s-=400;
  if(cfg.minLen && e.shortest<cfg.minLen) s-=(cfg.minLen-e.shortest)*60;
  if(cfg.maxLen && e.shortest>cfg.maxLen) s-=(e.shortest-cfg.maxLen)*40;
  if(cfg.wantDeath && !e.death) s-=400;
  if(cfg.noDeath && e.death) s-=400;
  if(cfg.minHaul && e.bestHaul<cfg.minHaul) s-=(cfg.minHaul-e.bestHaul)*200;
  if(cfg.haulMax && e.hauls.length>cfg.haulMax) s-=(e.hauls.length-cfg.haulMax)*20;
  return s;
}

function search(tpl,pool,mv,it,cfg={}){
  const slots=[]; const base=tpl.map(r=>r.split(''));
  base.forEach((row,y)=>row.forEach((c,x)=>{if(c==='?')slots.push([x,y]);}));
  let best=null,bestS=-Infinity;
  const iters=cfg.iters||400;
  for(let k=0;k<iters;k++){
    const g=base.map(r=>r.slice());
    for(const [x,y] of slots) g[y][x]=pool[(Math.random()*pool.length)|0];
    const rows=g.map(r=>r.join(''));
    const e=evaluate(rows,mv,it,cfg);
    const sc=score(e,cfg);
    if(sc>bestS){ bestS=sc; best={rows,e,sc}; }
  }
  return best;
}
function show(b,tag){
  if(!b||!b.e){console.log((tag||'')+' no solvable result');return;}
  console.log(tag||'');
  b.rows.forEach(r=>console.log('  '+r));
  const e=b.e;
  console.log(`  score=${b.sc.toFixed(0)} states=${e.states} free=${e.freePct.toFixed(0)}% traps=${e.trapPct.toFixed(0)}% routes=${e.routes} bad=${e.bad}/${e.near.length} topline=${e.topLine}(${e.topRun}) death=${e.death?'y':'n'} len=${e.shortest}`);
  console.log('  sols: '+e.near.slice(0,6).join(' '));
  console.log('  hauls: '+e.hauls.join(' '));
}
module.exports={evaluate,score,search,show,replay};
