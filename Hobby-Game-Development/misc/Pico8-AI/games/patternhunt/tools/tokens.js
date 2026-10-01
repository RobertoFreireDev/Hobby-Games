// tokens.js — approximate the pico-8 token count of a cart's __lua__ section.
// Rules per CLAUDE.md: a bracket PAIR is 1 token, a string is 1,
// commas / `local` / `end` / `.` / comments are free.  The editor is the
// ground truth; this is a budget check against the 8192 limit.
const fs = require('fs');

const cart = fs.readFileSync(process.argv[2] || 'game.p8', 'utf8');
const start = cart.indexOf('__lua__');
const end = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
let s = cart.slice(start + 8, end < 0 ? cart.length : end);

// strip comments (block first, then line) and tab markers
s = s.replace(/--\[\[[\s\S]*?\]\]/g, ' ').replace(/--[^\n]*/g, ' ');

const FREE = new Set(['end', 'local', 'then', 'do']);
let n = 0, i = 0;
const isName = (c) => /[A-Za-z0-9_]/.test(c);

while (i < s.length) {
  const c = s[i];
  if (/\s/.test(c)) { i++; continue; }

  // strings count as one token
  if (c === '"' || c === "'") {
    const q = c; i++;
    while (i < s.length && s[i] !== q) { if (s[i] === '\\') i++; i++; }
    i++; n++; continue;
  }
  if (s.startsWith('[[', i)) {
    const e = s.indexOf(']]', i + 2);
    i = e < 0 ? s.length : e + 2; n++; continue;
  }
  // names and numbers
  if (isName(c)) {
    let j = i;
    while (j < s.length && (isName(s[j]) || (s[j] === '.' && /[0-9]/.test(s[i])))) j++;
    const w = s.slice(i, j);
    if (!FREE.has(w)) n++;
    i = j; continue;
  }
  // closing brackets, commas, semicolons and field dots are free
  if (')]},;.'.includes(c)) { i++; continue; }
  // opening brackets count once for the pair
  if ('([{'.includes(c)) { n++; i++; continue; }
  // multi-char operators
  const two = s.substr(i, 2);
  if (['==', '~=', '!=', '<=', '>=', '..', '+=', '-=', '*=', '/=', '%=', '^=',
       '<<', '>>', '\\=', '..='].includes(two)) { n++; i += 2; continue; }
  n++; i++;
}

const pct = (n / 8192 * 100).toFixed(1);
console.log(`~${n} tokens of 8192 (${pct}%)  [approximate — confirm in the editor]`);
