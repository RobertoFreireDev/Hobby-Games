const G=require('./gen');const cfgs=require('./floorcfg');
const cfg=Object.assign({},cfgs[1]);
for(let i=0;i<5;i++){
  const t0=Date.now();
  const rows=G.build(cfg); if(!rows){console.log('build null');continue;}
  const tb=Date.now();
  const r=G.scoreLevel(rows,'bcb','',cfg);
  console.log('build',tb-t0,'ms  score',(Date.now()-tb),'ms  s=',r.s.toFixed(0),'states=',r.e&&r.e.states);
}
