const {decode}=require('./mapio'); const A=require('./analyze');
const lv=decode(process.argv[2]||'game.p8');
const hauls=[['aaa','']];
let mv=['a','a','a'],it=[];
const chain=["> > > >","vv> > ^^<","> > vvv<<<<<","><> vvv<<^<","> > v<v<^<","> > vvv<^^^<v","vvv> > >","vv> > X> > >","v> > Xv> v<<^^> ","vvv<<Xv<v> > ^^<","vvv^^> > vv<^vXv<> > ","> > > <XXv<> ","v> > v","> > v<<v<<<X> ","> > <<<v<vvv> > X> ","vvv> <<> ^X> Xv"].map(s=>s.replace(/ /g,''));
const R=require('./rules');
for(let n=1;n<=16;n++){
  const r=A.analyze(lv[n-1],mv,it);
  const sols=A.solutions(r,8);
  const uniq=[...new Set(sols.map(s=>s.line))];
  console.log(`floor ${n}  entry ${mv.join('')||'-'}/${it.join('')||'-'}  states=${r.states} wins=${r.wins.length} hauls=${r.hauls.size} traps=${(100*r.traps/r.states).toFixed(0)}% death=${r.deathReachable?'y':'n'}`);
  console.log(`   shortest: ${uniq.slice(0,4).map(l=>l+'('+A.maxRun(l)+')').join('  ')}`);
  console.log(`   chainline: ${chain[n-1]} maxrun=${A.maxRun(chain[n-1])}`);
  // advance along documented chain
  let s=R.start(lv[n-1],mv,it);
  const M={'<':0,'>':1,'^':2,'v':3,'X':4};
  for(const ch of chain[n-1]){const rr=R.apply(s,M[ch]); if(rr.s)s=rr.s;}
  mv=s.mv; it=s.it;
}
