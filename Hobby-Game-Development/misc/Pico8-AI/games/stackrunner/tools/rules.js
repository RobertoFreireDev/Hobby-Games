// exact model of stackrunner's rules, transcribed from game.p8
const BW=10,BH=9;
const SOLID={'#':1,'-':1,'2':1,'*':1};
const STP={a:1,b:2,c:3,d:99};
const DX=[-1,1,0,0], DY=[0,0,-1,1];
const MAXMV=5, MAXIT=3;

function parse(rows){
  const g=rows.join('').split('');
  let px=0,py=0;
  for(let i=0;i<g.length;i++) if(g[i]==='p'){px=i%BW;py=(i/BW)|0;g[i]='.';}
  return {g,px,py};
}
const at=(s,x,y)=> (x<0||y<0||x>=BW||y>=BH)?'#':s.g[y*BW+x];
const set=(s,x,y,c)=>{s.g[y*BW+x]=c;};

function clone(s){return {g:s.g.slice(),px:s.px,py:s.py,fx:s.fx,fy:s.fy,mv:s.mv.slice(),it:s.it.slice(),bf:s.bf};}
function key(s){return s.g.join('')+'|'+s.px+','+s.py+','+s.fx+','+s.fy+'|'+s.mv.join('')+'|'+s.it.join('')+'|'+s.bf;}

function step(s,vx,vy){
  const nx=s.px+vx, ny=s.py+vy;
  const c=at(s,nx,ny);
  if(SOLID[c]) return false;
  if(c==='o'){
    if(at(s,nx+vx,ny+vy)!=='.') return false;
    set(s,nx+vx,ny+vy,'o'); set(s,nx,ny,'.');
  }
  s.px=nx; s.py=ny;
  return true;
}
function pick(s,x,y){
  const c=at(s,x,y);
  if(STP[c]){ if(s.mv.length<MAXMV){ s.mv.push(c); set(s,x,y,'.'); } }
  else if(c==='x'||c==='y'){ if(s.it.length<MAXIT){ s.it.push(c); set(s,x,y,'.'); } }
}
function boom(s){
  for(let y=0;y<BH;y++)for(let x=0;x<BW;x++){
    if(at(s,x,y)==='*'){
      set(s,x,y,'.');
      for(let d=0;d<4;d++){
        const c=at(s,x+DX[d],y+DY[d]);
        if(c==='o'||c==='2') set(s,x+DX[d],y+DY[d],'.');
      }
    }
  }
}
// returns 'ok' | 'win' | 'dead'
function endturn(s){
  if(at(s,s.px,s.py)==='^') return 'win';
  for(let d=0;d<4;d++) if(at(s,s.px+DX[d],s.py+DY[d])==='2') return 'dead';
  return 'ok';
}

// act: 0..3 move, 4 use item.
// returns {s,res} where res is 'ok'|'win'|'dead'|'noop'|'stuck'
function apply(s0,act){
  const s=clone(s0);
  if(act===4){
    if(s.it.length<1) return {res:'noop'};
    const i=s.it[s.it.length-1];
    const tx=s.px+s.fx, ty=s.py+s.fy;
    if(i==='x' && at(s,tx,ty)!=='.') return {res:'noop'};
    s.it.pop();
    if(i==='x'){ set(s,tx,ty,'*'); s.bf=1; }
    else { for(let k=0;k<s.g.length;k++){ if(s.g[k]==='-')s.g[k]='='; else if(s.g[k]==='=')s.g[k]='-'; } }
    return {s,res:'ok'};
  }
  if(s.mv.length<1) return {res:'stuck'};
  const n=s.mv.pop();
  const path=[];
  if(!step(s,DX[act],DY[act])) return {res:'noop'};
  path.push([s.px,s.py]);
  s.fx=DX[act]; s.fy=DY[act];
  const lim=STP[n];
  for(let i=2;i<=lim;i++){
    if(at(s,s.px,s.py)==='^') break;
    if(!step(s,s.fx,s.fy)) break;
    path.push([s.px,s.py]);
  }
  for(const [x,y] of path) pick(s,x,y);
  if(s.bf===1){ s.bf=0; boom(s); }
  return {s,res:endturn(s)};
}

function start(rows,mv,it){
  const {g,px,py}=parse(rows);
  return {g,px,py,fx:1,fy:0,mv:mv.slice(),it:it.slice(),bf:0};
}
module.exports={BW,BH,DX,DY,parse,at,set,clone,key,apply,start,STP,MAXMV,MAXIT};
