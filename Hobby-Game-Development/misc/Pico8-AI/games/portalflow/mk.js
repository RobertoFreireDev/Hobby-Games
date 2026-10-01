// mk.js — splice code.lua + levels.json into game.p8's __lua__ section,
// leaving the asset sections that gen.js (and the pico-8 editor) own alone.
//   node levelgen.js && node gen.js && node mk.js
'use strict';
const fs = require('fs');
const path = require('path');
const d = __dirname;
const CR = String.fromCharCode(13);

const cart = fs.readFileSync(path.join(d, 'game.p8'), 'utf8').split(CR).join('');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
if (i < 0) throw new Error('no asset section in game.p8 — run gen.js first');

const lv = JSON.parse(fs.readFileSync(path.join(d, 'levels.json'), 'utf8')).levels;
// pico-8 strings are byte-compared and uppercase is a different glyph set, so
// the portal marker ships lowercase.
const rows = lv.map((r) => '{"' + r.map((s) => s.toLowerCase()).join('","') + '"}');

let code = fs.readFileSync(path.join(d, 'code.lua'), 'utf8').split(CR).join('');
if (!code.includes('lv={}')) throw new Error('code.lua has no lv={} placeholder');
code = code.replace('lv={}', 'lv={\n ' + rows.join(',\n ') + '}');

fs.writeFileSync(path.join(d, 'game.p8'),
  cart.slice(0, cart.indexOf('__lua__') + 8) + code +
  (code.endsWith('\n') ? '' : '\n') + cart.slice(i));
console.log('game.p8 lua written: ' + lv.length + ' levels, ' +
  code.split('\n').length + ' lines');
