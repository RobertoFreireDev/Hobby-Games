// set-levels.js — writes levels.json's data into the lvs=/prs= lines of game.p8.
// game.p8 is the source of truth for the code; this only replaces the two data
// strings, so editing the cart in PICO-8 and regenerating levels can coexist.
// run: node games/gridlock/set-levels.js
const fs = require('fs');
const p = f => __dirname + '/' + f;
const { lvs, prs } = JSON.parse(fs.readFileSync(p('levels.json'), 'utf8'));
let cart = fs.readFileSync(p('game.p8'), 'utf8');
function swap(re, body) {
  if (!re.test(cart)) throw new Error('line not found: ' + re);
  cart = cart.replace(re, body);
}
swap(/^lvs=split\("[^"]*",",",false\)$/m, 'lvs=split("' + lvs + '",",",false)');
swap(/^prs=split\("[^"]*"\)$/m, 'prs=split("' + prs + '")');
fs.writeFileSync(p('game.p8'), cart);
console.log('wrote ' + lvs.split(',').length + ' levels and ' + prs.split(',').length + ' pars');
