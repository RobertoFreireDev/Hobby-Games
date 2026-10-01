// write tools/levels.txt into game.p8's __map__ section
const {encode}=require('./mapio'); const L=require('./levels');
const levels=L.load(process.argv[3]||'tools/levels.txt');
if(levels.length!==16){console.error('expected 16 floors, got '+levels.length);process.exit(1);}
encode(process.argv[2]||'game.p8',levels);
console.log('wrote '+levels.length+' floors into '+(process.argv[2]||'game.p8'));
