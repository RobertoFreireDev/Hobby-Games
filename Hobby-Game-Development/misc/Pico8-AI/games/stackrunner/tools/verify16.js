// full verification of a level set: per-floor stats, control experiments,
// chain uniqueness, and the concrete winning line for the pico-8 harness.
const L=require('./levels'); const A=require('./analyze'); const C=require('./chain');
const S=require('./search'); const fs=require('fs');
const file=process.argv[2]||'tools/levels.txt';
const START=process.env.START||'bcb';
const floors=L.load(file);
const CONTROL=[null,null,null,
  {cell:'o',repl:'#',what:'crate'},{cell:'o',repl:'#',what:'both crates'},
  null,null,{cell:'y',repl:'.',what:'every switch'},{cell:'x',repl:'.',what:'every bomb'},
  {cell:'x',repl:'.',what:'every bomb'},null,null,null,null,null,null];
const res=C.run(floors,START,'',{cap:400000});
console.log('WINNING CHAINS THROUGH ALL '+floors.length+' FLOORS: '+res.total);
let h=START+'/'; const chain=[]; const rows=[];
for(let n=1;n<=floors.length;n++){
  const r=res.floorRes(n,h);
  const viable=[...r.hauls.keys()].filter(e=>res.chains(n+1,e)>0);
  const sols=A.solutions(r,300);
  const uniq=[...new Set(sols.map(s=>s.line))];
  const shortest=uniq[0].length;
  const near=uniq.filter(l=>l.length<=shortest+2);
  const bad=near.filter(l=>A.maxRun(l)>2);
  const routes=new Set();
  for(const l of near){const p=S.replay(floors[n-1],h.split('/')[0],h.split('/')[1]||'',l); if(p)routes.add(p.pos);}
  // pick the shortest winning line that leads to a viable haul
  let line=null;
  for(const s of sols){ if(viable.includes(s.haul)&&A.maxRun(s.line)<=2){line=s;break;} }
  if(!line) for(const s of sols){ if(viable.includes(s.haul)){line=s;break;} }
  let ctl='-';
  const c=CONTROL[n-1];
  if(c){
    const alt=floors[n-1].map(r2=>r2.split('').map(ch=>ch===c.cell?c.repl:ch).join(''));
    ctl=c.what+' removed -> '+(S.evaluate(alt,h.split('/')[0],h.split('/')[1]||'',{cap:400000})?'STILL SOLVABLE (BAD)':'unsolvable (ok)');
  }
  rows.push({n,entry:h,states:r.states,traps:Math.round(100*r.traps/r.states),
    free:0,wins:r.wins.length,hauls:r.hauls.size,viable:viable.length,
    death:r.deathReachable,routes:routes.size,bad:bad.length,near:near.length,
    line:line&&line.line,exit:line&&line.haul,shortest,ctl,paths:uniq.length});
  console.log(`floor ${String(n).padStart(2)} entry ${h.padEnd(10)} states=${String(r.states).padStart(6)} traps=${String(Math.round(100*r.traps/r.states)).padStart(3)}% wins=${String(r.wins.length).padStart(4)} hauls=${String(r.hauls.size).padStart(2)} viable=${viable.length} routes=${routes.size} bad=${bad.length}/${near.length} death=${r.deathReachable?'y':'n'}`);
  console.log(`        line=${line?line.line:'NONE'} (maxrun ${line?A.maxRun(line.line):'-'}) -> ${line?line.haul:'-'}   control: ${ctl}`);
  if(!line){console.log('  DEAD END');break;}
  chain.push(line.line); h=line.haul;
}
fs.writeFileSync('tools/chain.json',JSON.stringify(chain));
fs.writeFileSync('tools/stats.json',JSON.stringify(rows,null,1));
console.log('chain written ('+chain.length+' floors, '+chain.join('').length+' presses)');
