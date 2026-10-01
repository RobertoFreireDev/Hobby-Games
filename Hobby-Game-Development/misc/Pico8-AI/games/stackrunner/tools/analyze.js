const R=require('./rules');
const CH=['<','>','^','v','X'];

// full reachable-state analysis of one floor from one entry haul
function analyze(rows,mv,it,opt={}){
  const cap=opt.cap||400000;
  const s0=R.start(rows,mv,it);
  const k0=R.key(s0);
  const seen=new Map(); // key -> {s,dist,prev:[[key,act]],win,dead}
  seen.set(k0,{s:s0,d:0,win:false,dead:false});
  const q=[k0];
  let head=0, deaths=0, wins=[];
  while(head<q.length && seen.size<cap){
    const k=q[head++]; const node=seen.get(k);
    if(node.win||node.dead) continue;
    for(let a=0;a<5;a++){
      const r=R.apply(node.s,a);
      if(r.res==='noop'||r.res==='stuck') continue;
      const nk=R.key(r.s);
      let nn=seen.get(nk);
      if(!nn){
        nn={s:r.s,d:node.d+1,win:r.res==='win',dead:r.res==='dead'};
        seen.set(nk,nn); q.push(nk);
        if(nn.dead) deaths++;
        if(nn.win) wins.push(nk);
      }
      (nn.prev=nn.prev||[]).push([k,a]);
    }
  }
  // which states can still reach a win (backward reachability)
  const alive=new Set();
  const stack=[...wins];
  wins.forEach(w=>alive.add(w));
  while(stack.length){
    const k=stack.pop();
    for(const [pk] of (seen.get(k).prev||[])){
      if(!alive.has(pk)){alive.add(pk);stack.push(pk);}
    }
  }
  // exit hauls
  const hauls=new Map();
  for(const w of wins){
    const s=seen.get(w).s;
    const h=s.mv.join('')+'/'+s.it.join('');
    if(!hauls.has(h))hauls.set(h,[]);
    hauls.get(h).push(w);
  }
  return {states:seen.size,seen,wins,hauls,alive,
    solvable:wins.length>0,
    traps:seen.size-alive.size,
    deathReachable:deaths>0,
    truncated:seen.size>=cap, start:k0};
}

// shortest press sequence to each win, plus distinct routes
function solutions(res,limit=40){
  const out=[];
  const ws=res.wins.slice().sort((p,q)=>res.seen.get(p).d-res.seen.get(q).d).slice(0,300);
  for(const w of ws){
    const seq=[]; let k=w;
    const guard=new Set();
    while(k!==res.start){
      const node=res.seen.get(k);
      // pick the predecessor with smallest d
      let best=null;
      for(const [pk,a] of node.prev){ const p=res.seen.get(pk); if(!best||p.d<res.seen.get(best[0]).d) best=[pk,a]; }
      seq.push(CH[best[1]]); k=best[0];
      if(guard.has(k))break; guard.add(k);
    }
    const s=res.seen.get(w).s;
    out.push({line:seq.reverse().join(''),haul:s.mv.join('')+'/'+s.it.join('')});
  }
  out.sort((a,b)=>a.line.length-b.line.length);
  return out.slice(0,limit);
}

// reconstruct a shortest press sequence to one specific win state
function lineFor(res,winKey){
  const seq=[]; let k=winKey; const guard=new Set();
  while(k!==res.start){
    const node=res.seen.get(k); if(!node||!node.prev) return null;
    let best=null;
    for(const [pk,act] of node.prev){ const p=res.seen.get(pk); if(!best||p.d<res.seen.get(best[0]).d) best=[pk,act]; }
    seq.push(CH[best[1]]); k=best[0];
    if(guard.has(k)) return null; guard.add(k);
  }
  return seq.reverse().join('');
}

// longest run of the same press character
function maxRun(line){
  let m=1,c=1;
  for(let i=1;i<line.length;i++){ if(line[i]===line[i-1]){c++;if(c>m)m=c;} else c=1; }
  return line.length?m:0;
}
module.exports={analyze,solutions,maxRun,lineFor,CH};
