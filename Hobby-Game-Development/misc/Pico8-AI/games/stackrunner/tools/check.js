const L=require('./levels'); const A=require('./analyze'); const C=require('./chain');
const file=process.argv[2]||'tools/levels.txt';
const floors=L.load(file);
if(floors.length!==16){console.log('WARN: '+floors.length+' floors parsed');}
const res=C.run(floors,'aaa','');
console.log('TOTAL WINNING CHAINS: '+res.total);
// walk the viable chain(s)
let h='aaa/';
for(let n=1;n<=floors.length;n++){
  const r=res.floorRes(n,h);
  const viable=[...r.hauls.keys()].filter(eh=>res.chains(n+1,eh)>0);
  const sols=A.solutions(r,60);
  const uniq=[...new Set(sols.map(s=>s.line))];
  const good=uniq.filter(l=>A.maxRun(l)<=2);
  console.log(`floor ${String(n).padStart(2)} entry ${h.padEnd(9)} states=${String(r.states).padStart(5)} traps=${String(Math.round(100*r.traps/r.states)).padStart(3)}% wins=${String(r.wins.length).padStart(3)} hauls=${String(r.hauls.size).padStart(2)} viable=${viable.length} death=${r.deathReachable?'y':'n'}`);
  console.log(`        sols(maxrun<=2): ${good.length}/${uniq.length}  shortest: ${uniq.slice(0,3).join(' ')}`);
  if(viable.length===0){console.log('   DEAD END');break;}
  h=viable[0];
}
