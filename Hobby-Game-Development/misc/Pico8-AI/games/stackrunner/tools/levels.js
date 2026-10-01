const fs=require('fs');
function load(p){
  const txt=fs.readFileSync(p,'utf8');
  const blocks=txt.split(/\r?\n\s*\r?\n/).map(b=>b.split(/\r?\n/).filter(l=>/^[#.opa-z\^=\-2*]{10}$/.test(l))).filter(b=>b.length===9);
  return blocks;
}
function save(p,levels){
  fs.writeFileSync(p,levels.map((l,i)=>'-- floor '+(i+1)+'\n'+l.join('\n')).join('\n\n')+'\n');
}
module.exports={load,save};
