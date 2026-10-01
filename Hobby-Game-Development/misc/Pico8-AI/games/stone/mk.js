// mk.js - splice code.lua + levels.json into game.p8, keeping the asset
// sections the pico-8 editor owns. run after levelgen.js.
'use strict';
const fs = require('fs'), path = require('path');
const d = __dirname;

const cart = fs.readFileSync(path.join(d, 'game.p8'), 'utf8');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
if (i < 0) throw new Error('no asset section in game.p8');

const lv = JSON.parse(fs.readFileSync(path.join(d, 'levels.json'), 'utf8'));
let code = fs.readFileSync(path.join(d, 'code.lua'), 'utf8');

const q = a => a.map(s => '"' + s + '"').join(',\n ');
code = code.replace('lvl={}', 'lvl={\n ' + q(lv.lvl) + '}');
code = code.replace('lws={}', 'lws={' + lv.lws.map(s => '"' + s + '"').join(',') + '}');
code = code.replace('tdat={}', 'tdat={\n ' + q(lv.tut.map(t => t.d)) + '}');
// the first two lessons publish no laws: there is nothing to deduce yet
code = code.replace('twl={"","","",""}',
  'twl={"","","' + lv.tut[2].w + '","' + lv.tut[3].w + '"}');

fs.writeFileSync(path.join(d, 'game.p8'),
  cart.slice(0, cart.indexOf('__lua__') + 8) + code + '\n' + cart.slice(i));
console.log('game.p8 written: ' + lv.lvl.length + ' levels, ' + lv.tut.length + ' lessons');
