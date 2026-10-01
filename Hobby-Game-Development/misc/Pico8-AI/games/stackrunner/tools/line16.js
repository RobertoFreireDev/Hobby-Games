// walk the sixteen floors picking, at each one, the exit haul that keeps the
// rest of the run alive (one-floor lookahead). fast enough to iterate on.
const L=require('./levels'); const A=require('./analyze'); const S=require('./search'); const fs=require('fs');
const floors=L.load(process.argv[2]||'tools/levels3.txt');
const START=process.env.START||'bcb';
const CAP=+(process.env.CAP||150000);
const sz=h=>{const[m,i]=h.split('/');return m.length*2+(i||'').length;};
let h=START+'/'; const chain=[]; const rows=[];
for(let n=1;n<=floors.length;n++){
  const [em,ei]=h.split('/');
  const r=A.analyze(floors[n-1],em.split('').filter(Boolean),(ei||'').split('').filter(Boolean),{cap:CAP});
  if(!r.solvable){console.log('floor '+n+' UNSOLVABLE from '+h);break;}
  const sols=A.solutions(r,300);
  const uniq=[...new Set(sols.map(s=>s.line))];
  const shortest=uniq[0].length;
  const near=uniq.filter(l=>l.length<=shortest+2);
  const bad=near.filter(l=>A.maxRun(l)>2);
  const routes=new Set();
  for(const l of near){const p=S.replay(floors[n-1],em,ei||'',l); if(p)routes.add(p.pos);}
  // pick the exit that the next floor can still be won from
  const hauls=[...r.hauls.keys()].sort((a,b)=>sz(b)-sz(a));
  let chosen=null, viable=[];
  for(const e of hauls){
    if(n===floors.length){viable.push(e);continue;}
    const [m2,i2]=e.split('/');
    const nx=A.analyze(floors[n],m2.split('').filter(Boolean),(i2||'').split('').filter(Boolean),{cap:CAP});
    if(nx.solvable) viable.push(e);
  }
  chosen=viable[0];
  if(!chosen){console.log('floor '+n+' leaves nothing the next floor can use');break;}
  let line=sols.find(s=>s.haul===chosen&&A.maxRun(s.line)<=2)||sols.find(s=>s.haul===chosen);
  if(!line){
    // the chosen haul is outside the shortest-300 sample: rebuild its line directly
    const ws=r.hauls.get(chosen).slice().sort((p,q)=>r.seen.get(p).d-r.seen.get(q).d);
    let bestL=null;
    for(const w of ws.slice(0,20)){const l=A.lineFor(r,w); if(l&&(!bestL||A.maxRun(l)<A.maxRun(bestL)))bestL=l;}
    line={line:bestL,haul:chosen};
  }
  let early=0,alive=0;
  for(const [k,nd] of r.seen){ if(nd.d<=shortest+2){ early++; if(r.alive.has(k))alive++; } }
  const freePct=Math.round(100*alive/early);
  console.log(`floor ${String(n).padStart(2)} entry ${h.padEnd(10)} states=${String(r.states).padStart(6)} traps=${String(Math.round(100*r.traps/r.states)).padStart(3)}% free=${String(freePct).padStart(3)}% wins=${String(r.wins.length).padStart(4)} hauls=${r.hauls.size} viable=${viable.length} routes=${routes.size} bad=${bad.length}/${near.length} death=${r.deathReachable?'y':'n'}`);
  console.log(`        line=${line.line} (maxrun ${A.maxRun(line.line)}) -> ${line.haul}`);
  chain.push(line.line);
  rows.push({n,entry:h,states:r.states,traps:Math.round(100*r.traps/r.states),free:freePct,wins:r.wins.length,
             hauls:r.hauls.size,viable:viable.length,routes:routes.size,bad:bad.length,near:near.length,
             death:r.deathReachable,line:line.line,exit:line.haul,paths:uniq.length,shortest});
  h=chosen;
}
fs.writeFileSync('tools/chain.json',JSON.stringify(chain));
fs.writeFileSync('tools/stats.json',JSON.stringify(rows,null,1));
console.log('chain: '+chain.length+' floors, '+chain.join('').length+' presses');
