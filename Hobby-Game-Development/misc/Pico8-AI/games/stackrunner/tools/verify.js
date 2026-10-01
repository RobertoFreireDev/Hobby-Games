const R=require('./rules'); const {decode}=require('./mapio');
const M={'<':0,'>':1,'^':2,'v':3,'X':4};
const lines=["> > > >","vv>>^^<","> > vvv<<<<<","><>vvv<<^<","> > v<v<^<","> > vvv<^^^<v","vvv> > >","vv> > X> > >","v> > Xv> v<<^^> ","vvv<<Xv<v> > ^^<","vvv^^> > vv<^vXv<> > ","> > > <XXv<> ","v> > v","> > v<<v<<<X> ","> > <<<v<vvv> > X> ","vvv> <<> ^X> Xv"].map(s=>s.replace(/ /g,''));
const lv=decode('game.p8');
let mv=['a','a','a'], it=[];
for(let n=1;n<=16;n++){
  let s=R.start(lv[n-1],mv,it);
  let res='ok';
  for(const ch of lines[n-1]){
    const r=R.apply(s,M[ch]);
    if(r.res==='noop'||r.res==='stuck'){res='BLOCKED';break;}
    s=r.s; res=r.res;
    if(res!=='ok')break;
  }
  console.log('floor',n,res,'mv='+(s.mv.join('')||'-'),'it='+(s.it.join('')||'-'));
  if(res!=='win'){console.log('FAIL');break;}
  mv=s.mv; it=s.it;
}
