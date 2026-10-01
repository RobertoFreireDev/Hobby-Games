// build.js -- splice generated data and assets into game.p8
//
//   node storygen.js --emit && node build.js
//
// game.p8 is the source of truth for the Lua. This script only replaces the
// region between the --<data> markers and the hex asset sections, so the cart
// stays editable in PICO-8 itself between builds.

'use strict';
const fs = require('fs');
const { buildGfx } = require('./gen-sprites.js');
const { buildSfx, buildMusic } = require('./audiogen.js');

const CART = 'game.p8';
let cart = fs.readFileSync(CART, 'utf8');

// --- the story data, between its markers inside __lua__
const data = fs.readFileSync('moonfall-data.lua', 'utf8')
  .split('\n').filter(l => l.startsWith('lay=') || l.startsWith('nig=')).join('\n');
if (!data.includes('lay=') || !data.includes('nig=')) {
  throw new Error('moonfall-data.lua is missing lay/nig -- run storygen.js --emit');
}
// Check the markers exist rather than checking the file changed size: a rebuild
// with unchanged data is a no-op, and must not look like a missing marker.
const marked = /--<data>\n[\s\S]*?--<\/data>/;
if (!marked.test(cart)) throw new Error('data markers not found in ' + CART);
cart = cart.replace(marked, '--<data>\n' + data + '\n--</data>');

// --- asset sections
function section(name, body) {
  const re = new RegExp('__' + name + '__\\n(?:[0-9a-f][0-9a-f \\n]*\\n)?(?=__|$)', 'm');
  const block = '__' + name + '__\n' + (body ? body + '\n' : '');
  if (!re.test(cart)) throw new Error('no __' + name + '__ section');
  cart = cart.replace(re, block);
}

section('gfx', buildGfx());
section('sfx', buildSfx());
section('music', buildMusic());

fs.writeFileSync(CART, cart);

const lua = cart.slice(cart.indexOf('__lua__'), cart.indexOf('__gfx__'));
console.log('wrote ' + CART);
console.log('  lua      ' + lua.split('\n').length + ' lines, ' + lua.length + ' chars');
console.log('  gfx      ' + buildGfx().split('\n').length + ' lines');
console.log('  sfx      ' + buildSfx().split('\n').length + ' slots');
console.log('  music    ' + buildMusic().split('\n').length + ' patterns');
