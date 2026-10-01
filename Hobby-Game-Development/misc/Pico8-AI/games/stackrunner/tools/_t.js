const S=require('./search');
const rows=["##########","#........#","#........#","#........#","#pabc.a^.#","#........#","#........#","#........#","##########"];
console.log(JSON.stringify(S.evaluate(rows,'aaa','',{}),(k,v)=>k==='r'?undefined:v).slice(0,600));
