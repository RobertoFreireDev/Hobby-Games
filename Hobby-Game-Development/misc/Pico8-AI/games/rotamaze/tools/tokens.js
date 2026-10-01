// rough token estimate for the __lua__ section. pico-8's own counter is
// only visible in the editor, so this is a sanity check against 8192, not
// gospel: comments, commas, `local`, `end` and `.` are free, a bracket
// pair counts once, everything else is one token.
'use strict';
const fs = require('fs');
const path = require('path');

const cart = fs.readFileSync(process.argv[2] ||
  path.join(__dirname, '..', 'game.p8'), 'utf8');
const start = cart.indexOf('__lua__');
const end = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
let src = cart.slice(start + 8, end);

// strip comments and tab markers, then strings (each string = 1 token)
src = src.replace(/--\[\[[\s\S]*?\]\]/g, '').replace(/--[^\n]*/g, '');
let strings = 0;
src = src.replace(/"(\\.|[^"\\])*"|'(\\.|[^'\\])*'/g, () => { strings++; return ' 0 '; });

const FREE = new Set(['local', 'end', ',', '.']);
const re = /(\bfunction\b|\bif\b|\bthen\b|\belse\b|\belseif\b|\bfor\b|\bwhile\b|\bdo\b|\breturn\b|\bbreak\b|\bnil\b|\btrue\b|\bfalse\b|\bnot\b|\band\b|\bor\b|\blocal\b|\bend\b|[A-Za-z_][A-Za-z0-9_]*|0x[0-9a-fA-F]+|\d+\.?\d*|\+=|-=|\*=|\/=|%=|\.\.=|==|!=|~=|<=|>=|\.\.|[-+*/%\\^#<>=(){}\[\];:,.])/g;

let count = strings, closers = 0;
let m;
while ((m = re.exec(src))) {
  const t = m[0];
  if (FREE.has(t)) continue;
  if (t === ')' || t === '}' || t === ']') { closers++; continue; }  // pairs count once
  count++;
}
console.log('lua lines :', src.split('\n').length);
console.log('strings   :', strings);
console.log('tokens    :', count, '(bracket closers not counted:', closers + ')');
console.log('budget    : 8192  ->', (100 * count / 8192).toFixed(1) + '% used');
