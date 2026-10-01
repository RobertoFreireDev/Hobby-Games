// tok.js — approximate PICO-8 token count for a .p8 cart's __lua__ section.
// PICO-8 counts every lexeme except: comments, whitespace, `,` `.` `local` `end`
// and the closing halves of bracket pairs (a pair costs 1).
// usage: node tok.js game.p8
const fs = require('fs');
const src = fs.readFileSync(process.argv[2], 'utf8');
const a = src.indexOf('__lua__');
const b = src.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
const code = src.slice(a + 8, b < 0 ? undefined : b);

const FREE = new Set([',', '.', 'local', 'end', ')', ']', '}']);
const OPS = ['...', '..=', '>>>', '<<=', '>>=', '\\=', '^^=', '==', '~=', '!=', '<=', '>=',
  '..', '+=', '-=', '*=', '/=', '%=', '^=', '&=', '|=', '<<', '>>', '^^',
  '+', '-', '*', '/', '%', '^', '#', '<', '>', '=', '(', ')', '[', ']', '{', '}',
  ';', ':', ',', '.', '&', '|', '~', '\\', '@', '$'];

let i = 0, n = 0;
const isw = c => /[A-Za-z0-9_ -￿]/.test(c);
while (i < code.length) {
  const c = code[i];
  if (/\s/.test(c)) { i++; continue; }
  // comments
  if (code.startsWith('--[[', i)) { const e = code.indexOf(']]', i); i = e < 0 ? code.length : e + 2; continue; }
  if (code.startsWith('--', i)) { const e = code.indexOf('\n', i); i = e < 0 ? code.length : e; continue; }
  if (code.startsWith('-->8', i)) { i += 4; continue; }
  // strings
  if (c === '"' || c === "'") {
    i++;
    while (i < code.length && code[i] !== c) { if (code[i] === '\\') i++; i++; }
    i++; n++; continue;
  }
  if (code.startsWith('[[', i)) { const e = code.indexOf(']]', i); i = e < 0 ? code.length : e + 2; n++; continue; }
  // numbers
  if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(code[i + 1] || ''))) {
    let j = i;
    if (code.startsWith('0x', i) || code.startsWith('0X', i)) { j += 2; while (j < code.length && /[0-9a-fA-F.]/.test(code[j])) j++; }
    else { while (j < code.length && /[0-9.]/.test(code[j])) j++; }
    i = j; n++; continue;
  }
  // words
  if (isw(c)) {
    let j = i;
    while (j < code.length && isw(code[j])) j++;
    const w = code.slice(i, j);
    if (!FREE.has(w)) n++;
    i = j; continue;
  }
  // operators / punctuation
  const op = OPS.find(o => code.startsWith(o, i));
  if (op) { if (!FREE.has(op)) n++; i += op.length; continue; }
  i++;
}
console.log(process.argv[2] + ': ~' + n + ' tokens (limit 8192, ' + (8192 - n) + ' free)');
