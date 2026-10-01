// level generator: lattice skeleton (no long straights, connected),
// then pieces placed at chosen roles, then cards. scored by the solver.
const S=require('./search');
const BW=10,BH=9;
const ri=n=>(Math.random()*n)|0;
const pk=a=>a[ri(a.length)];
const SOLIDC={'#':1};

function blank(){const g=[];for(let y=0;y<BH;y++){g.push([]);for(let x=0;x<BW;x++)g[y][x]=(x===0||y===0||x===BW-1||y===BH-1)?'#':'.';}return g;}
function runsOk(g,m){
  for(let y=1;y<BH-1;y++){let c=0;for(let x=1;x<BW-1;x++){if(g[y][x]!=='#'){c++;if(c>m)return false;}else c=0;}}
  for(let x=1;x<BW-1;x++){let c=0;for(let y=1;y<BH-1;y++){if(g[y][x]!=='#'){c++;if(c>m)return false;}else c=0;}}
  return true;
}
function opens(g){const o=[];for(let y=1;y<BH-1;y++)for(let x=1;x<BW-1;x++)if(g[y][x]!=='#')o.push([x,y]);return o;}
function reach(g,from,block){
  const seen=new Set([from.join(',')]),st=[from];
  while(st.length){const [x,y]=st.pop();
    for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){
      const nx=x+dx,ny=y+dy,k=nx+','+ny;
      if(nx<1||ny<1||nx>=BW-1||ny>=BH-1)continue;
      if(g[ny][nx]==='#')continue;
      if(block&&block.has(k))continue;
      if(!seen.has(k)){seen.add(k);st.push([nx,ny]);}
    }}
  return seen;
}
function connected(g){return reach(g,opens(g)[0]).size===opens(g).length;}
function lattice(cfg){
  const forms=cfg.forms||[[1,1,4],[1,-1,4],[1,2,5],[2,1,5],[1,3,5],[3,1,5],[1,1,3],[1,-2,5],[2,-1,5],[1,-1,3]];
  for(let t=0;t<300;t++){
    const f=pk(forms), r=ri(f[2]), g=blank();
    for(let y=1;y<BH-1;y++)for(let x=1;x<BW-1;x++)
      if(((((f[0]*x+f[1]*y)%f[2])+f[2])%f[2])===r) g[y][x]='#';
    for(let i=0;i<(cfg.jitter===undefined?2:cfg.jitter);i++){
      const x=1+ri(BW-2),y=1+ri(BH-2); g[y][x]=Math.random()<0.5?'#':'.';
    }
    if(!runsOk(g,cfg.maxStraight||4))continue;
    if(!connected(g))continue;
    if(opens(g).length<(cfg.minOpen||32))continue;
    return g;
  }
  return null;
}
const dist=(a,b)=>Math.abs(a[0]-b[0])+Math.abs(a[1]-b[1]);

// cells that separate p from st when made solid (placed pieces count as passable)
function cutCells(g,p,st,free){
  const out=[];
  for(const c of opens(g)){
    const k=c.join(',');
    if(k===p.join(',')||k===st.join(','))continue;
    if(free&&free.has(k))continue;
    if(!reach(g,p,new Set([k])).has(st.join(',')))out.push(c);
  }
  return out;
}

function build(cfg){
  const g=lattice(cfg); if(!g)return null;
  const cells=opens(g).sort(()=>Math.random()-0.5);
  let p=null,st=null;
  for(const a of cells){for(const b of cells){if(dist(a,b)>=(cfg.minDist||9)){p=a;st=b;break;}}if(p)break;}
  if(!p)return null;
  const key=c=>c.join(',');
  const used=new Set([key(p),key(st)]);
  const protect=new Set();
  const placed=[];
  for(const spec of (cfg.pieces||[])){
    let pool;
    if(spec.at==='cut'){
      pool=cutCells(g,p,st,used).filter(c=>!used.has(key(c)));
      if(spec.immovable) pool=pool.filter(c=>{
        for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]])
          if(g[c[1]-dy][c[0]-dx]!=='#'&&g[c[1]+dy][c[0]+dx]!=='#') return false;
        return true;
      });
    } else {
      pool=opens(g).filter(c=>!used.has(key(c)));
      if(spec.notCut){const cut=new Set(cutCells(g,p,st,used).map(key)); pool=pool.filter(c=>!cut.has(key(c)));}
    }
    if(!pool.length)return null;
    const c=pk(pool);
    used.add(key(c)); placed.push([spec.ch,c]);
    if(spec.push){ // keep one legal push open
      const dirs=[[1,0],[-1,0],[0,1],[0,-1]].filter(([dx,dy])=>
        g[c[1]-dy][c[0]-dx]!=='#'&&g[c[1]+dy][c[0]+dx]!=='#'&&!used.has(key([c[0]+dx,c[1]+dy])));
      if(!dirs.length)return null;
      const [dx,dy]=pk(dirs);
      protect.add(key([c[0]+dx,c[1]+dy]));
    }
  }
  g[p[1]][p[0]]='p'; g[st[1]][st[0]]='^';
  for(const [ch,c] of placed) g[c[1]][c[0]]=ch;
  for(const c of opens(g)) if(g[c[1]][c[0]]==='.') g[c[1]][c[0]]= protect.has(key(c))?'.':pk(cfg.pool);
  return g.map(r=>r.join(''));
}

function scoreLevel(rows,mv,it,cfg,floor){
  const e=S.evaluate(rows,mv,it,{cap:cfg.cap||40000});
  if(!e)return {s:-1e9};
  delete e.r; // drop the state graph: only the metrics are kept alive
  let s=0;
  s-=e.badFrac*700;
  s-=Math.max(0,(cfg.freeMin||65)-e.freePct)*10;
  s+=Math.min(e.routes,10)*20;
  if(e.routes<(cfg.routes||3))s-=600;
  if(cfg.minLen&&e.shortest<cfg.minLen)s-=(cfg.minLen-e.shortest)*80;
  if(cfg.maxLen&&e.shortest>cfg.maxLen)s-=(e.shortest-cfg.maxLen)*60;
  if(cfg.wantDeath&&!e.death)s-=600;
  if(cfg.noDeath&&e.death)s-=600;
  if(cfg.minHaul&&e.bestHaul<cfg.minHaul)s-=(cfg.minHaul-e.bestHaul)*450;
  if(e.hauls.length>(cfg.haulMax||12))s-=(e.hauls.length-(cfg.haulMax||12))*5;
  if(e.topRun>2)s-=500;
  const musts=(cfg.must||[]).length, forb=(cfg.forbid||[]).length;
  // the expensive checks only pay off if this layout could still win
  if(floor!==undefined && s+250*musts<floor) return {s:s-1,e};
  for(const m of (cfg.must||[])){
    const alt=rows.map(r=>r.split('').map(c=>c===m.cell?m.repl:c).join(''));
    if(S.evaluate(alt,mv,it,{cap:cfg.cap||40000})) s-=900; else s+=250;
  }
  if(floor!==undefined && s<floor) return {s:s-1,e};
  for(const h of (cfg.forbid||[])){
    const [fm,fi]=h.split('/');
    if(S.evaluate(rows,fm,fi||'',{cap:cfg.cap||40000})) s-=700;
    if(floor!==undefined && s<floor) return {s:s-1,e};
  }
  return {s,e};
}
function generate(mv,it,cfg){
  let best=null; const t0=Date.now();
  for(let k=0;k<(cfg.iters||2000);k++){
    if(cfg.ms&&Date.now()-t0>cfg.ms)break;
    const rows=build(cfg); if(!rows)continue;
    const r=scoreLevel(rows,mv,it,cfg,best?best.s:undefined);
    if(!best||r.s>best.s){best={rows,e:r.e,sc:r.s,s:r.s}; if(cfg.good&&r.s>=cfg.good)break;}
  }
  return best;
}
module.exports={generate,build,scoreLevel,lattice,cutCells};
