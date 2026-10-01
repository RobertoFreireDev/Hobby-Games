// mkharness.js — builds _test.p8 = game.p8 with driver.lua appended to __lua__.
// Optionally applies a mutation first, to prove the suite can fail:
//   node mkharness.js               -> clean harness
//   node mkharness.js <name>        -> harness with mutation <name> applied
const fs = require('fs');

// each mutation deliberately breaks one guarantee the suite claims to check
const MUT = {
  // filler: stop refusing digits that complete a pattern
  nofill: [/if not hit\(i\) then return true end/, 'if true then return true end'],
  // separation: let seeded groups grow right up against each other
  nosep: [/if gi\[b\] and gi\[b\]!=id then return false end/, ''],
  // connectivity: accept three cells however they are scattered
  noconn: [/if e<2 then return false end/, ''],
  // the run rule: drop the all-distinct requirement, so 1,1,3 passes
  norun: [/return h-l==2 and a!=b and a!=c and b!=c/, 'return h-l==2'],
  // diagonals: fall back to 4-way adjacency everywhere
  nodiag: [/if \(dx!=0 or dy!=0\)/, 'if (dx==0 or dy==0) and (dx!=0 or dy!=0)'],
  // the hue family: stop three cells of one colour from counting
  nohue: [/return a%6==b%6 and b%6==c%6/, 'return false'],
  // one family a round: pin every grid to the same rule
  onefam: [/tr=flr\(rnd\(3\)\)\+1/, 'tr=1'],
  // the size floor: let a 2-cell selection commit
  nofloor: [/if #sel<3 then return end/, 'if #sel<2 then return end'],
  // cursor: let a step land on a resolved cell
  noskip: [/if g\[i\]>=0 then\n   cur=i/, 'if true then\n   cur=i'],
  // cursor: leave it standing on the group it just cleared
  nofix: [/\n fix\(\)/, ''],
};

let cart = fs.readFileSync('game.p8', 'utf8');
const name = process.argv[2];
if (name) {
  const m = MUT[name];
  if (!m) throw new Error('unknown mutation: ' + name);
  if (!m[0].test(cart)) throw new Error('mutation ' + name + ' matched nothing');
  cart = cart.replace(m[0], m[1]);
}

const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
if (i < 0) throw new Error('no asset section marker found');
const dname = process.env.DRIVER || 'driver.lua';
const driver = fs.readFileSync(dname, 'utf8');
fs.writeFileSync('_test.p8', cart.slice(0, i) + driver + '\n' + cart.slice(i));
console.log('wrote _test.p8 from ' + dname + (name ? ' [mutation: ' + name + ']' : ''));
