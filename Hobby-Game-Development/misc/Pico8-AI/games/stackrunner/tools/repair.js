// make the whole-game chain unique with local single-cell edits.
const L=require('./levels'); const C=require('./chain'); const S=require('./search'); const A=require('./analyze');
const file=process.argv[2]||'tools/levels3.txt';
const START=process.env.START||'bcb';
let floors=L.load(file);
const CARDS=['.','a','b','c','d'];
const sz=h=>{const[m,i]=h.split('/');return m.length*2+(i||'').length;};

function quality(e){
  return e && e.badFrac===0 && e.topRun<=2 && e.routes>=2 && e.freePct>=40;
}
function repairFloor(m,keep,comps,mustExit){
  const g=floors[m-1];
  const [km,ki]=keep.split('/');
  let best=null;
  for(let y=1;y<8;y++)for(let x=1;x<9;x++){
    const cur=g[y][x];
    if(!'.abcd'.includes(cur))continue;
    for(const rep of CARDS){
      if(rep===cur)continue;
      const rows=g.map((r,yy)=>yy===y?r.slice(0,x)+rep+r.slice(x+1):r);
      const e=S.evaluate(rows,km,ki||'',{cap:200000});
      if(!e||!quality(e))continue;
      if(mustExit&&!e.hauls.includes(mustExit))continue;
      let ok=true;
      for(const cp of comps){
        const [cm,ci]=cp.split('/');
        if(S.evaluate(rows,cm,ci||'',{cap:200000})){ok=false;break;}
      }
      if(!ok)continue;
      const sc=e.routes*10+e.freePct;
      if(!best||sc>best.sc){best={rows,sc,e};}
    }
  }
  return best;
}
for(let pass=0;pass<24;pass++){
  const res=C.run(floors,START,'',{cap:200000});
  console.log('pass '+pass+': chains='+res.total);
  if(res.total===1){console.log('UNIQUE');break;}
  if(res.total===0){console.log('BROKEN - no winning chain');break;}
  let h=START+'/', fixed=false;
  for(let n=1;n<=floors.length;n++){
    const r=res.floorRes(n,h);
    const viable=[...r.hauls.keys()].filter(e=>res.chains(n+1,e)>0);
    if(viable.length===0){console.log('dead end at floor '+n);break;}
    if(viable.length>1 && n<floors.length){
      const keep=viable.slice().sort((a,b)=>sz(b)-sz(a))[0];
      const comps=viable.filter(v=>v!==keep);
      // what floor n+1 currently exits with on the kept branch, so the tail is untouched
      const rn=res.floorRes(n+1,keep);
      const nextViable=[...rn.hauls.keys()].filter(e=>res.chains(n+2,e)>0)
        .sort((a,b)=>sz(b)-sz(a))[0];
      console.log('  floor '+n+' has '+viable.length+' viable exits; repairing floor '+(n+1)+
                  ' to reject '+comps.join(' '));
      const fix=repairFloor(n+1,keep,comps,nextViable);
      if(fix){ floors[n]=fix.rows; fixed=true;
        console.log('   fixed floor '+(n+1)+'  routes='+fix.e.routes+' free='+fix.e.freePct.toFixed(0)+'%');
        L.save(file,floors);
      } else {
        console.log('   no single-cell repair for floor '+(n+1));
      }
      break;
    }
    h=viable[0];
  }
  if(!fixed){console.log('stuck');break;}
}
L.save(file,floors);
console.log('saved '+file);
