// regenerate LEVELS.md from the level set + verification stats + hand-written prose
const fs=require('fs'); const L=require('./levels');
const floors=L.load(process.env.LV||'tools/levels2.txt');
const stats=JSON.parse(fs.readFileSync('tools/stats.json','utf8'));
const prose=require('./prose');
const NAME={a:'move 1',b:'move 2',c:'move 3',d:'move max',o:'crate','2':'guard','-':'closed door','=':'open door',x:'bomb',y:'switch'};
const ORDER=['a','b','c','d','o','2','-','=','x','y'];
function pieces(g){
  const c={}; for(const row of g) for(const ch of row) c[ch]=(c[ch]||0)+1;
  const parts=ORDER.filter(k=>c[k]).map(k=>NAME[k]+(c[k]>1?' x'+c[k]:''));
  return parts.join(', ')+' - and '+(c['#']||0)+' wall tiles';
}
let out=[];
out.push(prose.head);
for(let i=0;i<floors.length;i++){
  const s=stats[i], p=prose.floors[i]||{};
  out.push(`## Floor ${i+1} - ${p.title||''}`);
  out.push('');
  out.push(`**Asks for:** ${p.asks||''}`);
  out.push('');
  out.push('```');
  floors[i].forEach(r=>out.push(r));
  out.push('```');
  out.push('');
  if(p.body){out.push(p.body);out.push('');}
  out.push(`**Pieces:** ${pieces(floors[i])}.`);
  out.push('');
  out.push(`**Verified line:** \`${s.line}\` - ${s.line.length} presses, entering with \`${s.entry.split('/')[0]||'-'}\` / items \`${s.entry.split('/')[1]||'-'}\`, leaving with \`${s.exit.split('/')[0]||'-'}\` / items \`${s.exit.split('/')[1]||'-'}\`. No key is pressed more than **${maxRun(s.line)}** times in a row.`);
  out.push('');
  if(p.fail){out.push(`**How you fail:** ${p.fail}`);out.push('');}
  if(s.ctl&&s.ctl!=='-'){out.push(`**Control experiment:** ${s.ctl}.`);out.push('');}
  out.push('| reachable states | winning routes near the short line | distinct wins | distinct hauls out | hauls that carry the run on | trap states | death reachable |');
  out.push('|---|---|---|---|---|---|---|');
  out.push(`| ${s.states} | ${s.routes} | ${s.wins} | ${s.hauls} | ${s.viable} | ${s.traps}% | ${s.death?'yes':'no'} |`);
  out.push('');
  out.push('---');
  out.push('');
}
out.push(prose.tail);
function maxRun(l){let m=1,c=1;for(let i=1;i<l.length;i++){if(l[i]===l[i-1]){c++;if(c>m)m=c;}else c=1;}return l.length?m:0;}
fs.writeFileSync(process.env.OUT||'LEVELS.md',out.join('\n'));
console.log('wrote LEVELS.md');
