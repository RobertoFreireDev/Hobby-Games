// tokens.js -- approximate PICO-8's token count for game.p8
//
//   node tokens.js
//
// There is no runtime stat for tokens (stat(0) is memory), and the real number
// is only visible in the PICO-8 editor. This is close enough to tell you
// whether you are near the 8192 wall, and which tab is spending them.
//
// PICO-8's rule: every name, number, string, operator and opening bracket is
// one token. Free: comments, whitespace, commas, '.', closing brackets,
// 'local', and 'end'.

'use strict';
const fs = require('fs');

const FREE = new Set([',', '.', ')', ']', '}', 'end', 'local']);

function countLua(src) {
  let i = 0, n = 0;
  const out = [];
  while (i < src.length) {
    const c = src[i];

    // whitespace
    if (/\s/.test(c)) { i++; continue; }

    // long comment / long string
    if (src.startsWith('--[[', i)) {
      const e = src.indexOf(']]', i); i = e < 0 ? src.length : e + 2; continue;
    }
    if (src.startsWith('--', i)) {
      const e = src.indexOf('\n', i); i = e < 0 ? src.length : e; continue;
    }
    if (src.startsWith('[[', i)) {
      const e = src.indexOf(']]', i); i = e < 0 ? src.length : e + 2; n++; continue;
    }

    // string literal -- one token no matter how long, which is the whole
    // reason the story data is packed into strings rather than tables
    if (c === '"' || c === "'") {
      i++;
      while (i < src.length && src[i] !== c) i += src[i] === '\\' ? 2 : 1;
      i++; n++; out.push('<string>'); continue;
    }

    // number (incl. hex and binary literals)
    if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(src[i + 1] || ''))) {
      const m = /^(0[xb][0-9a-fA-F.]+|[0-9]*\.?[0-9]+)/.exec(src.slice(i));
      i += m[0].length; n++; out.push(m[0]); continue;
    }

    // name / keyword
    if (/[A-Za-z_]/.test(c)) {
      const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(src.slice(i));
      i += m[0].length;
      if (!FREE.has(m[0])) { n++; out.push(m[0]); }
      continue;
    }

    // operators, longest first
    const ops = ['...', '..=', '>>>', '<<=', '>>=', '==', '~=', '!=', '<=', '>=',
                 '..', '+=', '-=', '*=', '/=', '%=', '^^', '<<', '>>'];
    const op = ops.find(o => src.startsWith(o, i));
    if (op) { i += op.length; n++; out.push(op); continue; }

    i++;
    if (!FREE.has(c)) { n++; out.push(c); }
  }
  return { n, out };
}

const cart = fs.readFileSync('game.p8', 'utf8');
const lua = cart.slice(cart.indexOf('__lua__') + 8, cart.search(/^__gfx__$/m));

const tabs = lua.split(/^-->8$/m);
let total = 0;
console.log('tab  tokens  first line');
tabs.forEach((t, i) => {
  const { n } = countLua(t);
  total += n;
  const label = (t.trim().split('\n')[0] || '').slice(0, 40);
  console.log(String(i).padStart(3) + '  ' + String(n).padStart(6) + '  ' + label);
});

const pct = (total / 8192 * 100).toFixed(1);
console.log('\ntotal ~' + total + ' / 8192  (' + pct + '%)');
console.log(total > 8192 ? 'OVER THE LIMIT' : 'headroom ~' + (8192 - total));
